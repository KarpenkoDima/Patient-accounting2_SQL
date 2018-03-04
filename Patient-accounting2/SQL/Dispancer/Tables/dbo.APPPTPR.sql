SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[APPPTPR](
	[APPPTPR] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nchar](5) NOT NULL,
 CONSTRAINT [PK_APPPTPR] PRIMARY KEY CLUSTERED 
(
	[APPPTPR] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
