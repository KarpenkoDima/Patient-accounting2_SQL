SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByGender] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetCustomerByGender]
(@ID INT)
AS
SELECT vgc.CustomerID, vgc.MedCard, vgc.CodeCustomer, vgc.LastName, vgc.FirstName,
       vgc.MiddleName, vgc.Birthday, vgc.Arch, vgc.APPPTPRID, vgc.GenderID,
       vgc.NotaBene
  FROM vGetCustomers AS vgc
WHERE vgc.GenderID = @ID

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByGender] TO [Sensitive_low] AS [dbo]
GO
