SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* [DispensaryMainTest].[dbo].[vGetAdminDivision] */

/* DispensaryMain.[dbo].[vGetAdminDivision] */

CREATE VIEW [dbo].[vGetAdminDivision]
AS
SELECT [AdminDivisionID]
      --,[Level]
      ,[Name]
      ,[SocrName]
      --,[CodeType]
FROM [dbo].[AdminDivision]


GO

GRANT SELECT ON [dbo].[vGetAdminDivision] TO [Sensitive_low] AS [dbo]
GO
