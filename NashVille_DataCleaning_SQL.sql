/* 
Data Cleaning - Nashville Project - Skills Covered :-

1 - Data Standardization :- Converting Data types, Update Existing Data (UPDATE, CONVERT, ALTER)
2 - Data Cleaning - Extracting and Parsing information, Hhandling Missing info (ALTER)
3 - Data Manipulation - Joining tables, Removing Duplicates, Using Temp Tables (JOIN, WITH, ROW_NUMBER(), DELETE)
4 - Syntax - (CHARINDEX, PARSENAME, SUBSTRING)

*/
USE nashville

-- (a) Data Exploration - Checking Data Types of COlumns, No. of rows, columns etc

SELECT *
FROM nashville..housing;

SELECT COUNT(*) AS NO_OF_ROWS
FROM nashville..housing

SELECT COUNT(*) AS NO_OF_COLUMNS
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'housing';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'housing';

-- (1) Standardized Sale Date

SELECT CONVERT(date,SaleDate) AS Sale_Date
FROM nashville..housing;

ALTER TABLE nashville..housing
Add Sale_Date DATE;

UPDATE nashville..housing
SET Sale_Date = CONVERT(date,SaleDate);

ALTER TABLE nashville..housing
DROP COLUMN SaleDate;

-- (2) Property Address Data Populate 

SELECT h1.[UniqueID ],h1.ParcelID, h1.PropertyAddress,h2.[UniqueID ], h2.ParcelID, h2.PropertyAddress
--UPDATE h2
--SET h2.PropertyAddress = h1.PropertyAddress
FROM nashville..housing as h1
JOIN nashville..housing as h2 ON
h1.ParcelID = h2.ParcelID
where h1.[UniqueID ] != h2.[UniqueID ] AND h2.PropertyAddress is Null

SELECT * FROM nashville..housing

-- (3) Extract City From Property Address

					--(a) Checking for the syntax to separate state and address

SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) - 1) AS Address, SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress)) AS State
FROM nashville..housing; 

					--(b) Adding the Clumns Address and State

ALTER TABLE nashville..housing
ADD Address NVARCHAR(100), City NVARCHAR(100);

					--(c) Population the Address and STate from the PropertyAddress Column

UPDATE nashville..housing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) - 1), City = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress));
					
					--(d) Removing the Column PropertyAddress since there is already Address and State created

ALTER TABLE nashville..housing
DROP COLUMN PropertyAddress;

SELECT *
FROM nashville..housing

					--(e) Extracting State,City from Owner Address

SELECT OwnerAddress
FROM nashville..housing

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) , 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM nashville..housing

ALTER TABLE nashville..housing
ADD OwnerState NVARCHAR(20), OwnerCIty NVARCHAR(20)

UPDATE nashville..housing
SET OwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

SELECT OwnerAddress, OwnerCity, OwnerState
FROM nashville..housing

-- (4) Changing Y and N to Yes and No and ViceVersa in the SOldAsVacant Column

SELECT DISTINCT SoldAsVacant, COUNT(*)
FROM nashville..housing
GROUP BY SoldAsVacant

UPDATE nashville..housing
SET SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;

-- (5) Removing Duplicates

SELECT *
FROM nashville..housing;

-- Creating Temporary table to filter out duplicate vallues and hereby remove them 

With Duplicate_Values AS
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, Sale_Date, Address, LegalReference, SalePrice ORDER BY UniqueID) row_num
FROM nashville..housing
--order by ParcelID
)

DELETE
FROM Duplicate_Values
WHERE row_num > 1





	

