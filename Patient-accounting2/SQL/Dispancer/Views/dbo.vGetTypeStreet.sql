SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetTypeStreet] */

/* DispensaryMain.[dbo].[vGetTypeStreet] */

CREATE VIEW [dbo].[vGetTypeStreet]
AS
SELECT [TypeStreetID]
      ,[Name]
      ,[SocrName]
FROM [dbo].[TypeStreet]

GO

GRANT SELECT ON [dbo].[vGetTypeStreet] TO [Sensitive_low] AS [dbo]
GO
