# Data Cleaning in SQL

## Table of Contents

- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools](#tools)
- [Preparation](#preparation)
- [Limitations](#limitations)
- [References](#references)

### Project Overview

In this project, we employed ETL techniques to significantly enhance the usability of a database containing information about sold properties. Our objective was to streamline the data transformation and loading processes to make the database more accessible and insightful

### Data Sources

[Here](https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx) is the data used in this project. It is an Excel worksheet. 

### Tools

- Python
- MySQL
- Excel

### Process

The first thing to do was to transform the xlsx file into csv in order to easily load it in MySQL. For that I used Python. 

First I tried an easier way but I couldn't make it work. 

```Python
import pandas as pd

df = pd.read_excel(r'Path')

df.to_csv(r'Path',index = False)

```
Turned out that I was missing writing the full path (file included). Since I couldn't fix it at the time, I came up with a different code:

```Python
import pandas as pd
import csv

df = pd.read_excel(r"Path")

header = df.columns
data = df.iloc[1:]

with open('Nashville.csv', 'w', newline='', encoding='UTF8') as f:
     writer = csv.writer(f)
     writer.writerow(header)
     for x in range(len(df.iloc[:])):

          writer.writerow(df.iloc[x])
```

Now that I had my csv, it was time to import it to MySQL. I tried the Import Wizard, but not only didn't work fine, but when it did, it was painfully slow. Had to be another way. A bit tedious to write, but proved to be so much better:

```SQL
create table nashville
(
UniqueID int,
ParcelID varchar(250),
LandUse varchar(250),
PropertyAddress varchar(250),
SaleDate datetime,
SalePrice int,
LegalReference varchar(250),
SoldAsVacant varchar(250), 
OwnerName varchar(250),
OwnerAddress varchar(250),
Acreage float,
TaxDistrict varchar(250),
LandValue int,
BuildingValue int,
TotalValue int,
YearBuilt year,
Bedrooms int,
FullBath int,
HalfBath int
);

-- Allow us to load external data into the table
show global variables like 'local_infile'; 
set global local_infile = 1;

-- Add data to table
load data
local infile 'Path'
into table nashville
character set latin1
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows

/*
(@col1, @col2, @col3, @col4, @col5, @col6, @col7, @col8, @col9, @col10, @col11, @col12, @col13, @col14, @col15, @col16, @col17, @col18, @col19)
set
	UniqueID = nullif(@col1, ''),
	ParcelID = nullif(@col2, ''),
	LandUse = nullif(@col3, ''),
	PropertyAddress = nullif(@col4, ''),
	SaleDate = nullif(@col5, ''),
	SalePrice = nullif(@col6, ''),
	LegalReference = nullif(@col7, ''),
	SoldAsVacant = nullif(@col8, ''),
	OwnerName = nullif(@col9, ''),
	OwnerAddress = nullif(@col10, ''),
	Acreage = nullif(@col11, ''),
	TaxDistrict = nullif(@col12, ''),
	LandValue = nullif(@col13, ''),
	BuildingValue = nullif(@col14, ''),
	TotalValue = nullif(@col15, ''),
	YearBuilt = nullif(@col16, ''),
	Bedrooms = nullif(@col17, ''),
	FullBath = nullif(@col18, ''),
	HalfBath = nullif(@col19, '')
;*/
```

It is only at this point that I could start cleaning the data with SQL. Here is the SQL code and the transformations I performed:
```SQL
-- Standarize Date Format:
alter table nashville
add SaleDateConverted Date;

update nashville
set SaleDateConverted = DATE_FORMAT(SaleDate, '%Y-%m-%d');

select SaleDateConverted from nashville;
-- ---------------------------------------------------------------------------------------

-- Populate Property Address data: 
-- There are numerous rows with empty PropertyAddress values. Most, if not all, of these occur because the Parcel ID is repeated in a previous row
-- To address this issue, our approach involves populating the PropertyAddress field in the rows lacking data with the PropertyAddress from the previous row that contains data, provided they share the same Parcel ID 
-- To accomplish this, we first need to perform a self-join within the same table

-- visualize the problem
select *
from nashville
where PropertyAddress = ''
order by ParcelID;

-- create the query
select a.UniqueID, a.ParcelID, a.PropertyAddress, b.UniqueID, b.ParcelID, b.PropertyAddress, coalesce(a.PropertyAddress, b.PropertyAddress) -- coalesce is used to check if we can use the information and replicate it in a new column using an IF statement
from nashville as a
join nashville as b
	on a.ParcelID = b.ParcelID -- With this filter, we merge the two tables by ParcelID. We end up with an identical duplicate table 
	and a.UniqueID <> b.UniqueID -- But the magic happens here, with this filter, which enforces that the table contains only those with different UniqueIDs. Thus, we have those with the same ParcelID but different UniqueID
where a.PropertyAddress is null; -- And here, we are left with the ones we want to modify, which are precisely the ones that do not have information

-- execute the update
update nashville as a
join nashville as b
	on a.ParcelID = b.ParcelID 
	and a.UniqueID <> b.UniqueID 
set a.PropertyAddress = coalesce(a.PropertyAddress, b.PropertyAddress) 
where a.PropertyAddress is null;
-- ---------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
-- The PropertyAddress and OwnerAddress fields contain additional information separated by delimiters

-- Using substring_index, we extract the content of the column we desire (PropertyAddress), specify the delimiter until which we want to display the content (','), and indicate which occurrence of that delimiter we want to use as a reference (1 = the first occurrence)
SELECT
SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address
FROM nashville;


-- By using -1, we select what comes after the comma. 
SELECT
SUBSTRING_INDEX(PropertyAddress, ',', -1) AS Address 
FROM nashville;

-- You can't separate values from a single column just like that. You need to create two new columns

-- We create the new columns and add the new data to them.
alter table nashville
add PropertySplitAddress varchar(255);
alter table nashville
modify PropertySplitAddress varchar(250); -- You can use 'modify' to change the data type of fields. I'm not sure if you can change the entire data type, but you can certainly modify the character length of a varchar.
update nashville
set PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);


alter table nashville
add PropertySplitCity varchar(250);
update nashville
set PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);

-- Now for the OwnerAddress: 

select SUBSTRING_INDEX(OwnerAddress, ',', -1) -- We can see that substring_index works for grabbing the first or last element, but it gets complicated when we want to extract only the middle one

select SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) -- To get the middle element, we need to nest the substring_index
from nashville;

-- We add the corresponding columns
alter table nashville
add OwnerSplitAddress varchar(250);
update nashville
set OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

alter table nashville
add OwnerSplitCity varchar(250);
update nashville
set OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

alter table nashville
add OwnerSplitState varchar(250);
update nashville
set OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

-- Change Y and N to Yes and No in "Sold As Vacant field

select distinct(SoldAsVacant), count(SoldAsVacant) -- There are values Y and values N instead of just Yes and No
from nashville
group by SoldAsVacant
order by 2;

select SoldAsVacant, case 
	 when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
     else SoldAsVacant
     end
from nashville;

update nashville
set SoldAsVacant = case 
	 when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
     else SoldAsVacant
     end;
-- ---------------------------------------------------------------------------------------

-- Remove Duplicates
-- It's not very common to do this in SQL, let alone removing data from the database.
-- We need to identify duplicates first. We'll use row_number() for that. Row_number() counts the rows within a specified dataset.
-- Partition by allows us to choose which elements we want to select for the dataset that row_number() will operate on (the dataset will be a temporary table).

-- How to identify a duplicate? By determining the number of columns that need to be the same for it to count as a duplicate. It could be one or several, or all of them. Ideally, it should be all of them, but in some cases, a few might be enough.

CREATE TEMPORARY TABLE TempRowNum AS
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    ORDER BY UniqueID
) AS row_num
FROM nashville;


-- First, we select the data before deletion:
SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, UniqueID
    FROM TempRowNum
    WHERE row_num > 1;

-- Now we delete.
DELETE FROM nashville
WHERE (ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, UniqueID) IN ( 
    SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, UniqueID
    FROM TempRowNum
    WHERE row_num > 1
);
-- ---------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
from nashville_v4;

alter table nashville_v4
drop column OwnerAddress,
drop column TaxDistrict, 
drop column PropertyAddress,
drop column SaleDate;

-- Now the dataset is much more usable 
```

And wwith this the process is over. At least for now. 

### Limitations

This code only works for MySQL. 

### Further improvements

- Deepen the cleaning process
- Analyze the information and create visualizations that convey the findings

### References
- The project guidelanes came from [@AlexTheAnalyst](https://www.youtube.com/channel/UC7cs8q-gJRlGwj4A8OmCmXg) Youtube channel. My main contributions were the transformation and loading of the data to MySQL and to adjust the SQL code from SQL Server to MySQL. There were several bumps in the road to achieve that.
-  [ChatGPT](https://chat.openai.com/) my loyal companion through this journey.
