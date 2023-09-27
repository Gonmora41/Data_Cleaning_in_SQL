-- Create the table
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
local infile 'YourFilePath'
into table nashville
character set latin1
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
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
;