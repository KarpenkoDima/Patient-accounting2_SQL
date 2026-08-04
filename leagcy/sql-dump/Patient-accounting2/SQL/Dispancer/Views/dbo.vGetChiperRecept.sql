SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetChiperRecept] */

/* DispensaryMain.[dbo].[vGetChiperRecept] */

CREATE VIEW [dbo].[vGetChiperRecept]
AS
SELECT [ChiperReceptID]
      ,[Name]
      ,[NotaBene]
FROM [dbo].[ChiperRecept]

GO

GRANT SELECT ON [dbo].[vGetChiperRecept] TO [Sensitive_low] AS [dbo]
GO
