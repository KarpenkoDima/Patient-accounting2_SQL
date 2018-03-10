SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetAddressByLand] */

/* [Dispensary].[dbo].[uspGetCustomerByLand] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetAddressByLand]
(@ID INT)
AS
  BEGIN
	WITH CTE(CustomerID)
	AS(
		SELECT
			vgr.CustomerID			
		FROM
			dbo.vGetRegister AS vgr	
			INNER JOIN dbo.vGetCustomers AS vgc
			ON vgc.CustomerID = vgr.CustomerID	
	WHERE vgr.LandID = @ID AND vgc.Arch =0
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
	  INNER JOIN CTE AS c 
	  ON c.CustomerID = vga.CustomerID

      
  END

GO

GRANT EXECUTE ON [dbo].[uspGetAddressByLand] TO [Sensitive_low] AS [dbo]
GO
