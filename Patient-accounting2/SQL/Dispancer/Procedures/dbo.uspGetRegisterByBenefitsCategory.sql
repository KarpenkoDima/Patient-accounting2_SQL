SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetRegisterByBenefitsCategory] */

/* [Dispensary].[dbo].[uspGetCustomerByBenefitsCategory] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetRegisterByBenefitsCategory]
(@ID INT)
AS
 BEGIN
WITH CTE_InvalidBenefits(CustomerID)
AS(
	SELECT
		vgi.CustomerID
	FROM
		dbo.vGetInvalid AS vgi
		INNER JOIN dbo.vGetInvalid_BenefitsCategory AS vgibc
		ON vgi.InvalidID = vgibc.invID
		INNER JOIN dbo.vGetBenefitsCategory AS vgbc
		ON vgbc.BenefitsCategoryID = vgibc.BenefitsID
		INNER JOIN dbo.vGetCustomers AS vgc
		ON vgc.CustomerID = vgi.CustomerID
WHERE vgbc.BenefitsCategoryID = @ID AND vgc.Arch =0
		
		
)
SELECT vgr.CustomerID,
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
  INNER JOIN CTE_InvalidBenefits AS cte
  ON cte.CustomerID = vgr.CustomerID

      
  END

GO

GRANT EXECUTE ON [dbo].[uspGetRegisterByBenefitsCategory] TO [Sensitive_low] AS [dbo]
GO
