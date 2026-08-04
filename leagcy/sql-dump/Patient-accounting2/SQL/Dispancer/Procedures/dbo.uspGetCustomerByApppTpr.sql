SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByApppTpr] */

/* Dispensary.[dbo].[vGetApppTpr] */

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE PROCEDURE [dbo].[uspGetCustomerByApppTpr]
(@ID INT)
AS

BEGIN
    SELECT
    	vgc.CustomerID,
    	vgc.MedCard,
    	vgc.CodeCustomer,
    	vgc.LastName,
    	vgc.FirstName,
    	vgc.MiddleName,
    	vgc.Birthday,
    	vgc.Arch,
    	vgc.APPPTPRID,
    	vgc.GenderID,
    	vgc.NotaBene
    FROM
    	dbo.vGetCustomers AS vgc
    WHERE vgc.APPPTPRID = @ID
END

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByApppTpr] TO [Sensitive_low] AS [dbo]
GO
