SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByApppTpr] */

/* Dispensary.[dbo].[vGetApppTpr] */

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE PROCEDURE [dbo].[uspGetAddressByApppTpr]
(@ID INT)
AS

BEGIN
	
	WITH CTE_ (CustomerID)
	AS(
		SELECT vgc.CustomerID FROM dbo.vGetCustomers AS vgc
		WHERE vgc.APPPTPRID =@ID
	)
	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ AS cte
	 ON cte.CustomerID = vga.CustomerID  
END

GO

GRANT EXECUTE ON [dbo].[uspGetAddressByApppTpr] TO [Sensitive_low] AS [dbo]
GO
