SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetLand] */

/* DispensaryMain.[dbo].[vGetLand] */

CREATE VIEW [dbo].[vGetLand]
AS
SELECT        LandID, NumberLand AS [Name]
FROM            dbo.Land

GO

GRANT SELECT ON [dbo].[vGetLand] TO [Sensitive_low] AS [dbo]
GO
