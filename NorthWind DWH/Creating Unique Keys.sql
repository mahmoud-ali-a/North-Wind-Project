ALTER TABLE Dim_Customer
ADD CONSTRAINT Unique_CustomerID UNIQUE (CustomerID);

ALTER TABLE Dim_Employee
ADD CONSTRAINT Unique_employeeID UNIQUE (EmployeeID);

ALTER TABLE Dim_Product
ADD CONSTRAINT Unique_ProductID UNIQUE (ProductID);

ALTER TABLE Dim_Shipper
ADD CONSTRAINT Unique_ShipperID UNIQUE (ShipperID);

ALTER TABLE Dim_Supplier
ADD CONSTRAINT Unique_SupplierID UNIQUE (SupplierID);

ALTER TABLE Dim_ShipInfo
ADD CONSTRAINT Unique_OrderID2 UNIQUE (OrderID);