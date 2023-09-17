#!/usr/bin/ksh


function createDatabase {
	read name?"Please enter the database name:  "
            while true ; do
            	if [[ -d $name ]]; then
            		read name?"Database already exists. Please enter a new databasename:  "
            	elif ! [[  $name =~ ^[a-zA-Z0-9]+$ ]]; then                
               		read name?"invalid database name. Please enter a valid database name:  "
            	else
                	mkdir $name
                	print "Database $name created successfully"
                	break
            	fi
            done
}

function listDatabases {
	   if [ -n "$( ls -d */ 2>/dev/null )" ]; then
    		print "Current databases are:"
    		for dir in $(ls -d */); do
     		   basename $dir
  		done
	   else
  		  print "There are no databases."
	   fi
}


function connectDatabase {

	    if ! [ -n "$( ls -d */ 2>/dev/null )" ]; then              
                print "There are no databases to connect to."         
            else 
            read name?"please select a database to connect to: "
            if ! [[ -d "$name" ]]; then
                print "The database $name does not exist."
            else
            	print "You are now connected to $name database."
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
  					  print "There are no tables to show."
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
                            *) print "Unknown command" ;;
                        esac
                    done
                done  
            fi
            fi
  }          

function dropDatabase { 
	if ! [ -n "$( ls -d */ 2>/dev/null )" ]; then              
        	        print "There are no databases to drop."         
       	else 
        	    read name?"Please enter the database name you want to delete: "
        	    if [ -d "$name" ]; then
        	        rm -r $name
        	        print "$name deleted successfully"
        	    else
        	        print "Database $name does not exist."
        	    fi
        fi
 } 





function createTable {
    primary=0
    header=""
    tableStructure=""
    colNames=""

    read tableName?"Please enter table name you want to create:  "
    if [[ ! $tableName =~ ^[a-zA-Z0-9]+$ ]]; then
        print "Wrong name. Name should only contain alphanumeric characters."
        return 1
    fi
    if [[ -f $tableName ]]; then
        print "table already exists"
        return 1
    else 
        read colNum?"Please enter number of columns:  "
        while ! [[ $colNum =~ ^[0-9]+$ && $colNum -gt 0 ]]; do
            read colNum?"Wrong number. Please enter an valid positive number:  "
        done            
        for ((i=1; i<=colNum; i++))
        do
            while true; do
            	read colName?"Please enter the column name number $i :  "
            	if [[ $colNames == *"$colName"* ]]; then
                	print "Column name already used. Please enter a unique name."
            	elif ! [[  $colName =~ ^[a-zA-Z0-9]+$ ]]; then
                	print "Wrong column name, Name must only contain alphanumeric characters. Please enter again."
            	else
                	colNames+=" $colName"
                	break
        	    fi
            done	 
            read colType?"Please enter the column type (int, str):  "
            while [[ $colType != "int" && $colType != "str" ]]; do
                print "Wrong column Type, Please enter the column type (int, str)"  
                read colType?"Please enter the column type (int, str):  "
            done 
            if [[ $primary -eq 0 && $colNum -gt 1 ]]; then
                while true ; do
                    read pkey?"is this column primary key? (y/n)"
                    if [ $pkey = "y" ]; then
                        primary=1 
                        break                   
                    elif [ $pkey = "n" ]; then
                    	break
                    else 	
                        print "Wrong answer please try again"    
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
    	print "Error creating table, no primary key assigned."
    else	
    	print $tableStructure > $tableName"Structure"
    	print $header > $tableName
    	print "table successfully created"
    fi
	
}


function insertData {


if ! [[ -n $(ls | grep -v "Structure$") ]]; then
	print "There are no tables to insert into."
else		
    row=""
    read tableName?"Please enter table name you want to insert data into :  "
    if ! [[ -f $tableName ]]; then
        print "table doesn't exists"
    else 
        
        colNum=`awk 'END { print NR }' $tableName'Structure'`
        for (( i = 1; i < colNum; i++ )); do 
            colName=$(awk 'BEGIN{FS=":"}{ if(NR=='$i') print $1}' $tableName"Structure")
            colType=$(awk 'BEGIN{FS=":"}{if(NR=='$i') print $2}' $tableName"Structure")
            colKey=$(awk 'BEGIN{FS=":"}{if(NR=='$i') print $3}' $tableName"Structure")
            read data?"Please enter $colName Value of type ($colType) =  "
    
            while true; do
                if [[ $colType == 'int' && ! $data =~ ^[0-9]+$  ]]; then
                    read data?"Invalid type, please enter valid datatype for the current column:  "
                elif [[ $colType == 'str' && ! $data =~ ^[a-zA-Z0-9]+$ ]]; then
                    read data?"Invalid syntax, please enter valid alphanumerical value for the current column:  "
                elif [[ $colKey == 'primary' ]]; then
                    existingKeys=$(awk -v i=$i 'BEGIN{FS=":" ; ORS=" "}{if(NR != 1)print $(i)}' $tableName)                    
                    if [[ " ${existingKeys[@]} " =~ " ${data} " ]]; then
                        read data?"Error: Primary key already exists. Please enter a unique value:  "
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
        
        print $row >> $tableName
        print "Data sucussefully inserted"
        sed '/^$/d' $tableName > temp
        mv temp $tableName
    fi
fi
}


function deleteRow {
if ! [[ -n $(ls | grep -v "Structure$") ]]; then
	print "There are no tables to delete from."
else	
    read tableName?"Please enter table name you want to delete data from :  "
    if ! [[ -f $tableName ]]; then
        print "table doesn't exists"    
    elif [[ "$(grep -vc '^$' "$tableName")" -eq 1 ]]; then
   	 print "Table is empty."  	 
    else 
            read colName?"Please enter the column name:  "
            colNum=$(awk 'BEGIN{FS=":"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$colName'") print i}}}' $tableName)
            if [[ $colNum == "" ]]; then
                print "column doesn't exist."
            else
                read markValue?"Please mark value to delete its entire row:  "
                rowNum=$(awk 'BEGIN{FS=":"}{if ($'$colNum'=="'$markValue'") print NR }' $tableName)
                if [[ $rowNum == "" ]]; then
                    print "mark value not found."    
                else
                    sed -i'' -e "$rowNum d" $tableName
                    print "Row successfully deleted"  
                    sed '/^$/d' $tableName > temp
                    mv temp $tableName
                      
                fi 
            fi
        fi
    fi
}


function updateTable {

if ! [[ -n $(ls | grep -v "Structure$") ]]; then
	print "There are no tables to update."
else
    read tableName?"Please enter table name you want to update :  "
    if ! [[ -f $tableName ]]; then
        print "table doesn't exists"
    elif [[ "$(grep -vc '^$' "$tableName")" -eq 1 ]]; then
        print "Table is empty."
    else        
        # ASK THE USER FOR UPDATE COLUMN NAME
        read updateColName?"Please enter the column's name you want to update:  "
        updateColField=$(awk 'BEGIN{FS=":"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$updateColName'") print i}}}' $tableName)
        
        if [[ $updateColField == "" ]]; then
            print "Column doesn't exist."
        else
            # ASK THE USER FOR CONDITION COLUMN NAME
            read conditionColName?"Please enter the colume on which basis you want to change the value of $updateColName:  "
            conditionColField=$(awk 'BEGIN{FS=":"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$conditionColName'") print i}}}' $tableName)
            
            if [[ $conditionColField == "" ]]; then
                print "Column doesn't exist."
            else
                # ASK THE USER TO ENTER CONDITION COLUMN VALUE
                read conditionColValue?"Please enter the condition column's value:  "
                temp=$(awk 'BEGIN{FS=":"}{if ($'$conditionColField'=="'$conditionColValue'") print $'$conditionColField'}' $tableName)
                                
                if [[ $temp == "" ]]; then
                    print "Value doesn't exist"
                else 
                    # ask user to enter the new value , get the update colm type and if the constraint is primary or not
                    read updateValue?"Please enter the  update value:  "
                    colType=$(awk -F: '$1=="'$updateColName'" {print $2}' $tableName"Structure")
                    colKey=$(awk -F:  '$1=="'$updateColName'" {print $3}' $tableName"Structure")
                    if [[ $colKey == "primary" ]];then
                    	updateRow=$(awk 'BEGIN{FS=":"}{if ($'$conditionColField'=="'$conditionColValue'") {print NR; exit}}' $tableName)
                    else                                     
                    	updateRow=$(awk -v col="$conditionColField" -v val="$conditionColValue" 'BEGIN{FS=":"}{if ($col==val) {print NR}}' $tableName)

                    fi
                    while true; do
                        if [[ $colType == 'int' && ! $updateValue =~ ^[0-9]+$ ]]; then
                            read updateValue?"Invalid type, please enter valid datatype ($colType) for the current column:  "
                        elif [[ $colKey == 'primary' ]]; then
                            existingKeys=$(awk -v i=$updateColField -v row=$updateRow 'BEGIN{FS=":" ; ORS=" "}{if(NR != 1 && NR != row) print $(i)}' $tableName)
                            if [[ " ${existingKeys[@]} " =~ " ${updateValue} "  ]]; then
                                read updateValue?"Error: Primary key already exists. Please enter a unique value:  "
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
                        		print "Current value doesn't exist"
                        		return 1
                        	else	
    					sed -i ''$row's/'$oldValue'/'$updateValue'/' $tableName
				fi
			done
                        print "Field successfully updated"
                    fi  
                fi  
            fi
        fi     
    fi      
}



function selectTableAll {
if ! [[ -n $(ls | grep -v "Structure$") ]]; then
	print "There are no tables to show."
else
	read tableName?"Please enter table name you want to display :  "
	    if ! [[ -f $tableName ]]; then
                print "table doesn't exists"
    	    elif [[ "$(grep -vc '^$' "$tableName")" -eq 1 ]]; then
            		print "Table is empty."
            else	
            		
    		grep . $tableName | column -t -s ':'
    		
    	fi    fi			
	
}


function dropTable {

		if [[ -n $(ls | grep -v "Structure$") ]]; then
   			read tableName?"Please enter the table name you want to delete:  "
                        if [ -f "$tableName" ]; then
                               rm $tableName
                               print "$tableName successfully deleted." 
                                                             	 	
                        else
                                print "$tableName doesn't exist."
                        fi
                        
                        if [ -f "$tableName"Structure ];then
                                rm "$tableName"Structure
			fi
		else 	
  			print "There are no tables to drop."
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
            print "please enter a valid choice number between 1 and 5"
        esac
    done
done


