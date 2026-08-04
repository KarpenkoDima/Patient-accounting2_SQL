SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vGetCustomers]
AS
	SELECT c.CustomerID, c.MedCard, c.CodeCustomer, c.LastName, c.FirstName, c.MiddleName, c.Birthday, c.Arch, c.APPPTPRID, c.GenderID, cnb.NotaBene
	FROM Customer AS c
	LEFT JOIN CustomerNotaBene AS cnb
	ON c.CustomerID = cnb.CustomerID
	WHERE c.Arch =0;

GO

GRANT SELECT ON [dbo].[vGetCustomers] TO [Sensitive_low] AS [dbo]
GO
