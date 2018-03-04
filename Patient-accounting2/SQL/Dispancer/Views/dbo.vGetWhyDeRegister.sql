SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetWhyDeRegister] */

/* DispensaryMain.[dbo].[vGetWhyDeRegister] */

CREATE VIEW [dbo].[vGetWhyDeRegister]
AS
SELECT        WhyDeRegisterID, [Name], [NotaBene]
FROM            dbo.WhyDeRegister

GO

GRANT SELECT ON [dbo].[vGetWhyDeRegister] TO [Sensitive_low] AS [dbo]
GO
