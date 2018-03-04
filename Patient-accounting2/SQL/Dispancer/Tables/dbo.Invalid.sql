SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Invalid](
	[InvalidID] [int] IDENTITY(1,1) NOT NULL,
	[DisabilityGroupID] [int] NULL,
	[DataInvalidity] [datetime] NULL,
	[PeriodInvalidity] [datetime] NULL,
	[ChiperReceptID] [int] NULL,
	[Incapable] [bit] NOT NULL,
	[DateIncapable] [datetime] NULL,
	[CustomerID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Invalid_InvalidID] PRIMARY KEY CLUSTERED 
(
	[InvalidID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Invalid]  WITH CHECK ADD  CONSTRAINT [FK_Invalid_ChiperRecept_ChiperReceptID] FOREIGN KEY([ChiperReceptID])
REFERENCES [dbo].[ChiperRecept] ([ChiperReceptID])
ON UPDATE CASCADE
ON DELETE SET DEFAULT
GO

ALTER TABLE [dbo].[Invalid] CHECK CONSTRAINT [FK_Invalid_ChiperRecept_ChiperReceptID]
GO

ALTER TABLE [dbo].[Invalid]  WITH CHECK ADD  CONSTRAINT [FK_Invalid_Customer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Invalid] CHECK CONSTRAINT [FK_Invalid_Customer_CustomerID]
GO

ALTER TABLE [dbo].[Invalid]  WITH CHECK ADD  CONSTRAINT [FK_Invalid_DisabilityGroup_DisabilityGroupID] FOREIGN KEY([DisabilityGroupID])
REFERENCES [dbo].[DisabilityGroup] ([DisabilityGroupID])
ON UPDATE CASCADE
ON DELETE SET DEFAULT
GO

ALTER TABLE [dbo].[Invalid] CHECK CONSTRAINT [FK_Invalid_DisabilityGroup_DisabilityGroupID]
GO

ALTER TABLE [dbo].[Invalid]  WITH NOCHECK ADD  CONSTRAINT [CK_Invalid_DataInvalidity_GetDate] CHECK  (([DataInvalidity]<=getdate()))
GO

ALTER TABLE [dbo].[Invalid] CHECK CONSTRAINT [CK_Invalid_DataInvalidity_GetDate]
GO

ALTER TABLE [dbo].[Invalid]  WITH NOCHECK ADD  CONSTRAINT [CK_Invalid_PeriodInvalidity_GetDate] CHECK  (([PeriodInvalidity]<=getdate()))
GO

ALTER TABLE [dbo].[Invalid] CHECK CONSTRAINT [CK_Invalid_PeriodInvalidity_GetDate]
GO

ALTER TABLE [dbo].[Invalid] ADD  CONSTRAINT [DF_Invalid_Incapable_TEMP]  DEFAULT ('0') FOR [Incapable]
GO

ALTER TABLE [dbo].[Invalid] ADD  CONSTRAINT [DF_Invalid_ModifiedDate_TEMP]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
