SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Customer](
	[CustomerID] [int] NOT NULL,
	[����������� �������� ������������� �������� �] [int] NULL,
	[��� ��������(���)] [int] NULL,
	[�������] [nvarchar](50) NOT NULL,
	[���] [nvarchar](50) NULL,
	[��������] [nvarchar](50) NULL,
	[���] [nvarchar](50) NULL,
	[���� ��������] [datetime2](0) NULL,
	[�������] [nvarchar](50) NULL,
	[APPPTPDID] [int] NULL
) ON [PRIMARY]

GO
