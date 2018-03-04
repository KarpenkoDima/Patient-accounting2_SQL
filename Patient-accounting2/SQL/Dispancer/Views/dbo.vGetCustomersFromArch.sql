SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vGetCustomersFromArch]
AS
	SELECT c.CustomerID, c.MedCard, c.CodeCustomer, c.LastName, c.FirstName, c.MiddleName, c.Birthday, c.Arch, c.APPPTPRID, c.GenderID, cnb.NotaBene
	FROM Customer AS c
	LEFT JOIN CustomerNotaBene AS cnb
	ON c.CustomerID = cnb.CustomerID
	WHERE c.Arch =1;

GO

GRANT SELECT ON [dbo].[vGetCustomersFromArch] TO [Sensitive_low] AS [dbo]
GO
