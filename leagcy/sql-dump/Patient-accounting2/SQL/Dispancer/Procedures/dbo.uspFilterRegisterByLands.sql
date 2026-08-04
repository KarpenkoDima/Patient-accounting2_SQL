SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspFilterRegisterByLands] */

/* [Dispensary].[dbo].[uspGetCustomerByLand] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspFilterRegisterByLands]
(@landid NVARCHAR(100))
AS
  BEGIN

		DECLARE @sqlQuery NVARCHAR(700)
		SET @sqlQuery =  N'SELECT vgr.CustomerID,          
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID  FROM dbo.vGetRegister AS vgr
	 INNER JOIN dbo.vGetCustomers AS vgc ON vgr.CustomerID = vgc.CustomerID
	WHERE vgr.LandID  in('+@landid+') AND vgc.Arch =0';
		 EXEC sp_executesql @sqlQuery
	END

GO
