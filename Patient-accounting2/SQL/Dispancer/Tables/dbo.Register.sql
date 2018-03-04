SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Register](
	[RegisterID] [int] IDENTITY(1,1) NOT NULL,
	[FirstRegister] [datetime] NULL,
	[FirstDeregister] [datetime] NULL,
	[SecondRegister] [datetime] NULL,
	[Diagnosis] [nvarchar](10) NULL,
	[DataDiagnosis] [datetime] NULL,
	[RegisterTypeID] [int] NULL,
	[CustomerID] [int] NOT NULL,
	[WhyDeRegisterID] [int] NULL,
	[LandID] [int] NOT NULL,
	[NotaBene] [ntext] NULL,
	[SecondDeRegister] [datetime] NULL,
	[SecondRegisterTypeID] [int] NULL,
	[WhySecondDeRegisterID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Register_RegisterID] PRIMARY KEY CLUSTERED 
(
	[RegisterID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

EXEC sys.sp_addextendedproperty @name=N'Column_DataDiagnosis', @value=N'Это тоже самое что и 1-й раз взят на регшистрацию(почти) - за отсутствием некоторых дат.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Register'
GO

ALTER TABLE [dbo].[Register]  WITH CHECK ADD  CONSTRAINT [FK_Register_Customer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Register] CHECK CONSTRAINT [FK_Register_Customer_CustomerID]
GO

ALTER TABLE [dbo].[Register]  WITH CHECK ADD  CONSTRAINT [FK_Register_Land_LandID] FOREIGN KEY([LandID])
REFERENCES [dbo].[Land] ([LandID])
ON UPDATE CASCADE
ON DELETE SET DEFAULT
GO

ALTER TABLE [dbo].[Register] CHECK CONSTRAINT [FK_Register_Land_LandID]
GO

ALTER TABLE [dbo].[Register]  WITH CHECK ADD  CONSTRAINT [FK_Register_RegisterType_RegisterTypeID] FOREIGN KEY([RegisterTypeID])
REFERENCES [dbo].[RegisterType] ([RegisterTypeID])
ON UPDATE CASCADE
ON DELETE SET DEFAULT
GO

ALTER TABLE [dbo].[Register] CHECK CONSTRAINT [FK_Register_RegisterType_RegisterTypeID]
GO

ALTER TABLE [dbo].[Register]  WITH CHECK ADD  CONSTRAINT [FK_Register_RegisterType_SecondRegisterTypeID] FOREIGN KEY([SecondRegisterTypeID])
REFERENCES [dbo].[RegisterType] ([RegisterTypeID])
GO

ALTER TABLE [dbo].[Register] CHECK CONSTRAINT [FK_Register_RegisterType_SecondRegisterTypeID]
GO

ALTER TABLE [dbo].[Register]  WITH CHECK ADD  CONSTRAINT [FK_Register_WhyDeRegister_WhyDeRegisterID] FOREIGN KEY([WhyDeRegisterID])
REFERENCES [dbo].[WhyDeRegister] ([WhyDeRegisterID])
ON UPDATE CASCADE
ON DELETE SET NULL
GO

ALTER TABLE [dbo].[Register] CHECK CONSTRAINT [FK_Register_WhyDeRegister_WhyDeRegisterID]
GO

ALTER TABLE [dbo].[Register]  WITH CHECK ADD  CONSTRAINT [FK_Register_WhyDeRegister_WhySecondDeRegisterID] FOREIGN KEY([WhySecondDeRegisterID])
REFERENCES [dbo].[WhyDeRegister] ([WhyDeRegisterID])
GO

ALTER TABLE [dbo].[Register] CHECK CONSTRAINT [FK_Register_WhyDeRegister_WhySecondDeRegisterID]
GO

ALTER TABLE [dbo].[Register] ADD  DEFAULT ((1)) FOR [LandID]
GO

ALTER TABLE [dbo].[Register] ADD  CONSTRAINT [DF_Register_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
