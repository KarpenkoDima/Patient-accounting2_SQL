SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetRegisterByGender] */

/* [Dispensary].[dbo].[uspGetCustomerByGender] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetRegisterByGender]
(@ID INT)
AS
BEGIN
	WITH CTE_ (CustomerID)
	AS(
		SELECT vgc.CustomerID FROM dbo.vGetCustomers AS vgc
		WHERE vgc.GenderID =@ID
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
           vgr.WhySecondDeRegisterID
	FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ AS cte
	 ON cte.CustomerID = vgr.CustomerID  
END

GO

GRANT EXECUTE ON [dbo].[uspGetRegisterByGender] TO [Sensitive_low] AS [dbo]
GO
