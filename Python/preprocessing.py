# The function below reads the raw data from the EPA (data-source), search for all the
# necessary information we need, stores these infomation and finally write this data 
# to a new csv. file!

def preprocessing():
    import os 
    from rpy2.robjects import pandas2ri
    pandas2ri.activate()
  
    a=[] #this will be a list with the header elements
    b=[] #this will be a list of lists with all the data belonging to the header elements
    readfile=open('Python/data/data.csv', 'r')
    n = "No Data" # emty cells will be filled with the text "No Data"   
    for line in readfile: 
        l = line.split(",")
        l = [item.strip('\n') for item in l]
        l = [item.strip('"') for item in l]    
        
        # If the first element is "Date", the row is the headerline (a).
        if l[0] == 'Date': 
            a += [l[0], l[3], l[4], l[11], l[13], l[15], l[16],l[17]] 
        
        # Not all the lines have the same number of commas (causes problems with the split command). 
        # In column 11, some rows have an additional comma. Therefore we need the 
        # if/else statement which is written down below. 
        else: 
            if l[11] != '':
                b += [[l[0], l[3], l[4], l[11], l[14], l[16], l[17],l[18]]] 
            else:
                b += [[l[0], l[3], l[4], n, l[13], l[15], l[16],l[17]]] 
    
    # Extract all the coordinates from every list in list b, this variable is not  
    # used anymore in the script, but we don't want to the delete this part still.
    coordinates = []
    for row in b:
        lat = row[6]
        lon = row[7]
        coordinates += [(lat, lon)]
    
    # List b (which contains thousands of lists, each list is a meassurement of 
    # one of the monitoring stations), will be converted to a dictionary. The columns
    # will be the keys and all the belonging data will be added as key-values.  
    # The dictionary will be written as a .csv file whereby the keys are the headers
    # and all key-values are the underneath data. 
    
    # The final product of the function is a new .csv file with all the data and
    # information we need for the rest of the project in a good stucture. 
    dic = {}
    for column in range(len(a)):
        lijst = []
        for i in range(len(b)): 
            lijst += [b[i][column]]
            dic[a[column]]=lijst 
    
    output = "Python/output"
    if not os.path.exists(output):
        os.makedirs(output)
    with open("Python/output/preprocessing_results.csv","w") as f:
        f.write(",".join(dic.keys()) + "\n")
        for row in zip(*dic.values()):
            f.write(",".join(str(n) for n in row) + "\n")
        f.close() 
        

preprocessing()      




        