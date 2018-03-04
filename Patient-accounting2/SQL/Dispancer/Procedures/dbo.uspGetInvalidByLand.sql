SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetInvalidByLand] */

/* [Dispensary].[dbo].[uspGetCustomerByLand] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetInvalidByLand]
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

	SELECT  vgi.ChiperReceptID,
            vgi.CustomerID,          
            vgi.DataInvalidity,
            vgi.DateIncapable,
            vgi.DisabilityGroupID,
            vgi.Incapable,
            vgi.InvalidID,
            vgi.ModifiedDate,
            vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	  INNER JOIN CTE AS c 
	  ON c.CustomerID = vgi.CustomerID

      
  END

GO
