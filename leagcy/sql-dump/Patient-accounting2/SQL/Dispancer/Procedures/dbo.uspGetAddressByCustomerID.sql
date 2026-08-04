SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetAddressByCustomerID] */

/* [Dispensary13102017].[dbo].[uspGetAddressByCustomerID] */

CREATE PROCEDURE [dbo].[uspGetAddressByCustomerID]
(@CustomerID INT)
AS
BEGIN
    SELECT [AddressID]
          ,[CustomerID]
          ,[Region]
          --,[Contry]
          ,[City]
          ,[AdminDivisionID]
          ,[TypeStreetID]
          ,[NameStreet]
          ,[NumberHouse]
          ,[NumberApartment]
          --,[ModifiedDate]
           FROM dbo.vGetAddress AS vga
    WHERE vga.CustomerID = @CustomerID
END

GO

GRANT EXECUTE ON [dbo].[uspGetAddressByCustomerID] TO [Sensitive_low] AS [dbo]
GO
