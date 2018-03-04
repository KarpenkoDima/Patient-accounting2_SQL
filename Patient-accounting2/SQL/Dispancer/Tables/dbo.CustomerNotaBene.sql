SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerNotaBene](
	[CustomerID] [int] NOT NULL,
	[NotaBene] [ntext] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[CustomerNotaBene]  WITH CHECK ADD  CONSTRAINT [FK_NotaBene_Customer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[CustomerNotaBene] CHECK CONSTRAINT [FK_NotaBene_Customer_CustomerID]
GO
