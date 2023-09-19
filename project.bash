#!/usr/bin/bash


createDatabase() {
    read -p "Please enter the database name:  " name
    while true ; do
        if [[ -d $name ]]; then
            read -p "Database already exists. Please enter a new database name:  " name
        elif ! [[  $name =~ ^[a-zA-Z][a-zA-Z0-9]*$ ]]; then                
            read -p "Invalid database name. Please enter a valid database name:  " name
        else
            mkdir $name
            echo "Database $name created successfully"
            break
        fi
    done
}

listDatabases() {
    if [ -n "$( ls -d */ 2>/dev/null )" ]; then
        echo "Current databases are:"
        for dir in $(ls -d */); do
            basename $dir
        done
    else
        echo "There are no databases."
    fi
}

connectDatabase() {
    if ! [ -n "$( ls -d */ 2>/dev/null )" ]; then              
        echo "There are no databases to connect to."         
    else 
        read -p "please select a database to connect to: " name
        if ! [[ -d "$name" ]]; then
            echo "The database $name does not exist."
        else
            echo "You are now connected to $name database."
            cd $name/
            while true ; do
                select innerChoice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select All From Table" "Delete From Table" "Update Table"  "Return to previous menu"
                do
                    case $innerChoice in
                        "Create Table") 
                            createTable
                            break;;
                        "List Tables") 
                            if [[ -n $(ls | grep -v "Structure$") ]]; then
                                ls | grep -v "Structure$"
                            else 
                                echo "There are no tables to show."
                            fi

                            break;;
                        "Drop Table") 
                            dropTable
                            break;;
                        "Insert into Table") 
                            insertData 
                            break;;
                        "Select All From Table") 
                            selectTableAll 
                            break;;
                        "Delete From Table") 
                            deleteRow
                            break;;
                        "Update Table" ) 
                            updateTable 
                            break;;
                        "Return to previous menu")
                            cd ..
                            
                            break 2 ;;    
                        *) echo "Unknown command" ;;
                    esac
                done
            done  
        fi
    fi
}

dropDatabase() { 
    if ! [ -n "$( ls -d */ 2>/dev/null )" ]; then              
        echo "There are no databases to drop."         
    else 
        read -p "Please enter the database name you want to delete: " name
        if [ -d "$name" ]; then
            rm -r $name
            echo "$name deleted successfully"
        else
            echo "Database $name does not exist."
        fi
    fi
}





createTable() {
    primary=0
    header=""
    tableStructure=""
    colNames=""

    read -p "Please enter table name you want to create:  " tableName
    if [[ ! $tableName =~ ^[a-zA-Z][a-zA-Z0-9]*$ ]]; then
        echo "Wrong name. Name should only contain alphanumeric characters."
        return 1
    fi
    if [[ -f $tableName ]]; then
        echo "table already exists"
        return 1
    else 
        read -p "Please enter number of columns:  " colNum
        while ! [[ $colNum =~ ^[0-9]+$ && $colNum -gt 0 ]]; do
            read -p "Wrong number. Please enter a valid positive number:  " colNum
        done            
        for ((i=1; i<=colNum; i++))
        do
            while true; do
                read -p "Please enter the column name number $i :  " colName
                if [[ $colNames == *"$colName"* ]]; then
                    echo "Column name already used. Please enter a unique name."
                elif ! [[  $colName =~ ^[a-zA-Z][a-zA-Z0-9]*$ ]]; then
                    echo "Wrong column name, Name must only contain alphanumeric characters. Please enter again."
                else
                    colNames+=" $colName"
                    break
                fi
            done     
            read -p "Please enter the column type (int, str):  " colType
            while [[ $colType != "int" && $colType != "str" ]]; do
                echo "Wrong column Type, Please enter the column type (int, str)"  
                read -p "Please enter the column type (int, str):  " colType
            done 
            if [[ $primary -eq 0 && $colNum -gt 1 ]]; then
                while true ; do
                    read -p "is this column primary key? (y/n)" pkey
                    if [ $pkey = "y" ]; then
                        primary=1 
                        break                   
                    elif [ $pkey = "n" ]; then
                        break
                    else     
                        echo "Wrong answer please try again"    
                    fi
                done
            fi
            if [[ $colNum -eq 1 || $primary -eq 1  ]]; then 
                tableStructure+=$colName":"$colType":primary\n"
                primary=2
            else
                tableStructure+=$colName":"$colType"\n"       
                                               
            fi                
            if [ $i -eq $colNum ]; then  
                header+=$colName
            else
                header+=$colName":"
            fi  
        done
        
    fi
    if [[ $primary -eq 0 ]]; then
        echo "Error creating table, no primary key assigned."
    else    
        echo -e $tableStructure > $tableName"Structure"
        echo $header > $tableName
        echo "table successfully created"
    fi
    
}



insertData() {
    if ! [[ -n $(ls | grep -v "Structure$") ]]; then
        echo "There are no tables to insert into."
    else        
        row=""
        read -p "Please enter table name you want to insert data into :  " tableName
        if ! [[ -f $tableName ]]; then
            echo "table doesn't exists"
        else 
            colNum=$(awk 'END { print NR }' $tableName'Structure')
            for (( i = 1; i < colNum; i++ )); do 
                colName=$(awk 'BEGIN{FS=":"}{ if(NR=='$i') print $1}' $tableName"Structure")
                colType=$(awk 'BEGIN{FS=":"}{if(NR=='$i') print $2}' $tableName"Structure")
                colKey=$(awk 'BEGIN{FS=":"}{if(NR=='$i') print $3}' $tableName"Structure")
                read -p "Please enter $colName Value of type ($colType) =  " data
        
                while true; do
                    if [[ $colType == 'int' && ! $data =~ ^[0-9]+$  ]]; then
                        read -p "Invalid type, please enter valid datatype for the current column:  " data
                    elif [[ $colType == 'str' && ! $data =~ ^[a-zA-Z0-9]+$ ]]; then
                        read -p "Invalid syntax, please enter valid alphanumerical value for the current column:  " data
                    elif [[ $colKey == 'primary' ]]; then
                        existingKeys=$(awk -v i=$i 'BEGIN{FS=":" ; ORS=" "}{if(NR != 1)print $(i)}' $tableName)                    
                        if [[ " ${existingKeys[@]} " =~ " ${data} " ]]; then
                            read -p "Error: Primary key already exists. Please enter a unique value:  " data
                        else
                            break
                        fi
                    else
                        break
                    fi
                done
        
                if [ $i -eq $(($colNum - 1)) ]; then
                    row+=$data"\n"
                else
                    row+=$data":"
                fi  
            done
            
            echo -e $row >> $tableName
            echo "Data successfully inserted"
            sed '/^$/d' $tableName > temp
            mv temp $tableName
        fi
    fi
}



deleteRow() {
    if ! [[ -n $(ls | grep -v "Structure$") ]]; then
        echo "There are no tables to delete from."
    else    
        read -p "Please enter table name you want to delete data from :  " tableName
        if ! [[ -f $tableName ]]; then
            echo "table doesn't exists"    
        elif [[ "$(grep -vc '^$' "$tableName")" -eq 1 ]]; then
            echo "Table is empty."     
        else 
            read -p "Please enter the column name:  " colName
            colNum=$(awk 'BEGIN{FS=":"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$colName'") print i}}}' $tableName)
            if [[ $colNum == "" ]]; then
                echo "column doesn't exist."
            else
                read -p "Please mark value to delete its entire row:  " markValue
                rowNum=$(awk 'BEGIN{FS=":"}{if ($'$colNum'=="'$markValue'") print NR }' $tableName)
                if [[ $rowNum == "" ]]; then
                    echo "mark value not found."    
                else
                    sed -i'' -e "$rowNum d" $tableName
                    echo "Row successfully deleted"  
                    sed '/^$/d' $tableName > temp
                    mv temp $tableName
                      
                fi 
            fi
        fi
    fi
}



updateTable() {
    if ! [[ -n $(ls | grep -v "Structure$") ]]; then
        echo "There are no tables to update."
    else
        read -p "Please enter table name you want to update :  " tableName
        if ! [[ -f $tableName ]]; then
            echo "table doesn't exists"
        elif [[ "$(grep -vc '^$' "$tableName")" -eq 1 ]]; then
            echo "Table is empty."
        else        
            # ASK THE USER FOR UPDATE COLUMN NAME
            read -p "Please enter the column's name you want to update:  " updateColName
            updateColField=$(awk 'BEGIN{FS=":"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$updateColName'") print i}}}' $tableName)
            
            if [[ $updateColField == "" ]]; then
                echo "Column doesn't exist."
            else
                # ASK THE USER FOR CONDITION COLUMN NAME
                read -p "Please enter the column on which basis you want to change the value of $updateColName:  " conditionColName
                conditionColField=$(awk 'BEGIN{FS=":"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$conditionColName'") print i}}}' $tableName)
                
                if [[ $conditionColField == "" ]]; then
                    echo "Column doesn't exist."
                else
                    # ASK THE USER TO ENTER CONDITION COLUMN VALUE
                    read -p "Please enter the condition column's value:  " conditionColValue
                    temp=$(awk 'BEGIN{FS=":"}{if ($'$conditionColField'=="'$conditionColValue'") print $'$conditionColField'}' $tableName)
                                    
                    if [[ $temp == "" ]]; then
                        echo "Value doesn't exist"
                    else 
                        # ask user to enter the new value , get the update colm type and if the constraint is primary or not
                        read -p "Please enter the  update value:  " updateValue
                        colType=$(awk -F: '$1=="'$updateColName'" {print $2}' $tableName"Structure")
                        colKey=$(awk -F:  '$1=="'$updateColName'" {print $3}' $tableName"Structure")
                        if [[ $colKey == "primary" ]];then
                            updateRow=$(awk 'BEGIN{FS=":"}{if ($'$conditionColField'=="'$conditionColValue'") {print NR; exit}}' $tableName)
                        else                                     
                            updateRow=$(awk -v col="$conditionColField" -v val="$conditionColValue" 'BEGIN{FS=":"}{if ($col==val) {print NR}}' $tableName)

                        fi
                        while true; do
                            if [[ $colType == 'int' && ! $updateValue =~ ^[0-9]+$ ]]; then
                                read -p "Invalid type, please enter valid datatype ($colType) for the current column:  " updateValue
                            elif [[ $colKey == 'primary' ]]; then
                                existingKeys=$(awk -v i=$updateColField -v row=$updateRow 'BEGIN{FS=":" ; ORS=" "}{if(NR != 1 && NR != row) print $(i)}' $tableName)
                                if [[ " ${existingKeys[@]} " =~ " ${updateValue} "  ]]; then
                                    read -p "Error: Primary key already exists. Please enter a unique value:  " updateValue
                                else
                                    break
                                fi
                            else
                                break
                            fi
                        done
                        
                        
                            for row in $updateRow
                            do
                                oldValue=$(awk -v row="$row" -v col="$updateColField" 'BEGIN{FS=":"}{if(NR==row) print $col}' $tableName)
                                if [[ $oldValue == "" ]]; then
                                    echo "Current value doesn't exist"
                                    return 1
                                else    
                                    sed -i ''$row's/'$oldValue'/'$updateValue'/' $tableName
                                fi
                            done
                        
                        echo "Field successfully updated"
                    fi  
                fi  
            fi     
        fi      
    fi      
}




function selectTableAll {
if ! [[ -n $(ls | grep -v "Structure$") ]]; then
	echo "There are no tables to show."
else
	read -p "Please enter table name you want to display :  " tableName
	    if ! [[ -f $tableName ]]; then
                echo "table doesn't exists"
    	    elif [[ "$(grep -vc '^$' "$tableName")" -eq 1 ]]; then
            		echo "Table is empty."
            else	
            		
    		grep . $tableName | column -t -s ':'
    		
    	fi    fi			
	
}


function dropTable {

		if [[ -n $(ls | grep -v "Structure$") ]]; then
   			read -p "Please enter the table name you want to delete:  " tableName
                        if [ -f "$tableName" ]; then
                               rm $tableName
                               echo "$tableName successfully deleted." 
                                                             	 	
                        else
                                echo "$tableName doesn't exist."
                        fi
                        
                        if [ -f "$tableName"Structure ];then
                                rm "$tableName"Structure
			fi
		else 	
  			echo "There are no tables to drop."
		fi
}          


        
 
 
      
while true; do
    select choice in "Create database" "List Databases" "Connect to Database" "Drop Database" "Exit the script"
    do
        case $choice in
        "Create database" )            
            createDatabase
            break
            ;;
        "List Databases" )
            listDatabases
            break
            ;;
        "Connect to Database" )        
            connectDatabase          
            break
            ;;
        "Drop Database" )
            dropDatabase
            break
            ;;
         "Exit the script" ) break 2;;   
        *)
            echo "please enter a valid choice number between 1 and 5"
        esac
    done
done


