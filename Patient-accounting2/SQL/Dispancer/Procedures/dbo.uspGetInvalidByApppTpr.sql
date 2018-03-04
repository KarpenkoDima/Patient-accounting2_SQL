SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetInvalidByApppTpr] */

/* [Dispensary].[dbo].[uspGetCustomerByApppTpr] */

/* Dispensary.[dbo].[vGetApppTpr] */

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE PROCEDURE [dbo].[uspGetInvalidByApppTpr]
(@ID INT)
AS

BEGIN
	
	WITH CTE_ (CustomerID)
	AS(
		SELECT vgc.CustomerID FROM dbo.vGetCustomers AS vgc
		WHERE vgc.APPPTPRID =@ID
	)
	SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ AS cte
	 ON cte.CustomerID = vgi.CustomerID  
END

GO
