SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetInvalidByCustomerID] */

/* [Dispensary].[dbo].[uspGetInvalidByCustomerID] */

CREATE PROCEDURE [dbo].[uspGetInvalidByCustomerID]
(@CustomerID INT)
AS
SELECT
	i.InvalidID,
	i.DisabilityGroupID,
	i.DataInvalidity,
	i.PeriodInvalidity,
	i.ChiperReceptID,
	i.Incapable,
	i.DateIncapable,
	i.CustomerID,
	i.ModifiedDate
FROM
	Invalid AS i
WHERE i.CustomerID = @CustomerID

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidByCustomerID] TO [Sensitive_low] AS [dbo]
GO
