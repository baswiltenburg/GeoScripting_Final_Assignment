import os
import csv
    
def read_data_fire_period():
    a=[] #this will be a list with the header elements
    b=[] #this will be a list of lists with all the data belonging to the header elements
    # Read the dataset with all data (created in air_pollution.R)    
    readfile=open('Dataframes/df_fire_period.csv', 'r')    
    for line in readfile: 
        l = line.split(",")
        l = [item.strip('\n') for item in l]
        l = [item.strip('"') for item in l]  
        # Define a column name to the first column (only if it is the headerline).        
        if l[0] == '':
            a += l
            a[0] = "ROW_NR"
        else:
            b += [l]
    return a,b #both variables are used in the follow-up functions

# header is a list with columnnames
# b is a list of list of lists with all the data belonging to the header elements
header, b = read_data_fire_period()

# Create a list of all unique dates (82 dates in total)
def create_list_dates(b): 
    lijst = [] # define a emty list where we put in the unique dates
    for i in range(len(b)): # this is looping over all the lines (= lists in b)
        for j in range(len(b[i])): # this is looping over all the columns in the lists in b
            if j == 8: # the dates are stored in the 8th column
                if b[i][j] not in lijst: # if a date is not yet in 'lijst', put in in there
                    lijst += [b[i][j]]
    lijst.sort()
    return lijst
    
lijst = create_list_dates(b) # save the results of this function in the variable 'lijst'
    

# Make separate dataframes with all data, for each unique date
def create_list_of_dataframes(b):
    lijst_dataframes = [] # Define an emty list to store all the 82 dataframes
    for i in range(len(lijst)): # loop trough the list with unique dates
        lijst_dataframes += [[]] # Create a new list in the list to keep the dataframes separate
        for j in range(len(b)):  # loop through all lines (lists in b)
            for k in range(len(b[j])): # than loop trough each single line (list in list b) to 
                if k == 8: # search for the 8th column which is the 'date' column
                    b[j][k] = str(b[j][k]) # convert this date to a string format
                    if lijst[i] == b[j][k]: #if the date is equal to the date in 'lijst':
                        lijst_dataframes[i] += [b[j]] # store all data in this line in one list in the list 'lijst_dataframes'

    return lijst_dataframes
# The result of this function is a list of lists. All lists in the list consist of data of only one unique date 
lijst_dataframes = create_list_of_dataframes(b)

# The function below writes all the lists (dataframes of unique dates) to separete .csv files 
def write_dataframes_to_csv(lijst_dataframes, header): # this .csv files will be readed in the 'air_pollution.R' script. 
    for i in range(len(lijst_dataframes)):
        a = str(i) 
        day = 'day_'
        extensie = '.csv'
        path = 'Dataframes/'
        filename = path+day+a+extensie # Give all .csv files a unique name (day 1 to 82)
        myfile = open(filename, 'wb')
        wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
        wr.writerow(header)
        for df in lijst_dataframes[i]:
            wr.writerow(df)
    #os.remove('Dataframes/day_82.csv') #Ignore
        
write_dataframes_to_csv(lijst_dataframes, header)

    

