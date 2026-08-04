SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Customer](
	[CustomerID] [int] NOT NULL,
	[Медицинская карточка амбулаторного больного №] [int] NULL,
	[Код больного(год)] [int] NULL,
	[Фамилия] [nvarchar](50) NOT NULL,
	[Имя] [nvarchar](50) NULL,
	[Отчество] [nvarchar](50) NULL,
	[Пол] [nvarchar](50) NULL,
	[Дата рождения] [datetime2](0) NULL,
	[Возрост] [nvarchar](50) NULL,
	[APPPTPDID] [int] NULL
) ON [PRIMARY]

GO
