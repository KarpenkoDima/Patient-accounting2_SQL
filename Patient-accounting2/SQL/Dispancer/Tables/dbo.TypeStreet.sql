SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TypeStreet](
	[Level] [int] NOT NULL,
	[Name] [nvarchar](30) NOT NULL,
	[SocrName] [nvarchar](10) NOT NULL,
	[CodeType] [int] NOT NULL,
	[TypeStreetID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_TypeStreet] PRIMARY KEY CLUSTERED 
(
	[TypeStreetID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
