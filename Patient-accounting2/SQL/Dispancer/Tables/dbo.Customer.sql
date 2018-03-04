SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Customer](
	[CustomerID] [int] IDENTITY(1,1) NOT NULL,
	[MedCard] [int] NULL,
	[CodeCustomer] [int] NULL,
	[LastName] [nvarchar](100) NOT NULL,
	[FirstName] [nvarchar](100) NOT NULL,
	[MiddleName] [nvarchar](100) NULL,
	[Birthday] [datetime] NULL,
	[Arch] [bit] NOT NULL,
	[CustomerTempID] [int] NULL,
	[APPPTPRID] [int] NULL,
	[GenderID] [int] NULL,
	[Delete] [bit] NULL,
	[ModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Customer_CustomerID] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[CancelDeleteRow] ON [dbo].[Customer]
INSTEAD OF DELETE AS
BEGIN
	IF @@ROWCOUNT = 0 RETURN
	
    UPDATE dbo.Customer
 SET dbo.Customer.[Delete] =1
 WHERE Customer.CustomerID in (select Deleted.CustomerID from deleted)
  End  

GO

ALTER TABLE [dbo].[Customer]  WITH CHECK ADD  CONSTRAINT [FK_Customer_APPPTPR_APPPTPRID] FOREIGN KEY([APPPTPRID])
REFERENCES [dbo].[APPPTPR] ([APPPTPR])
ON UPDATE CASCADE
ON DELETE SET DEFAULT
GO

ALTER TABLE [dbo].[Customer] CHECK CONSTRAINT [FK_Customer_APPPTPR_APPPTPRID]
GO

ALTER TABLE [dbo].[Customer]  WITH CHECK ADD  CONSTRAINT [FK_Customer_Gender_GenderID] FOREIGN KEY([GenderID])
REFERENCES [dbo].[Gender] ([GenderID])
ON UPDATE CASCADE
ON DELETE SET DEFAULT
GO

ALTER TABLE [dbo].[Customer] CHECK CONSTRAINT [FK_Customer_Gender_GenderID]
GO

ALTER TABLE [dbo].[Customer]  WITH NOCHECK ADD  CONSTRAINT [CK_Customer_BirthDay] CHECK  (([Birthday]<=getdate()))
GO

ALTER TABLE [dbo].[Customer] CHECK CONSTRAINT [CK_Customer_BirthDay]
GO

ALTER TABLE [dbo].[Customer] ADD  CONSTRAINT [DF__Customer__Delete]  DEFAULT ((0)) FOR [Delete]
GO

ALTER TABLE [dbo].[Customer] ADD  CONSTRAINT [DF_Customer_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
