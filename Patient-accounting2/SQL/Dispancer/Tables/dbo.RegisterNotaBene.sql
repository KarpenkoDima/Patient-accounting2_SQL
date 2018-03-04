SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RegisterNotaBene](
	[RegisterID] [int] NOT NULL,
	[NotaBene] [ntext] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[RegisterNotaBene]  WITH CHECK ADD  CONSTRAINT [FK_RegisterNotaBene_Register_RegisterID] FOREIGN KEY([RegisterID])
REFERENCES [dbo].[Register] ([RegisterID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[RegisterNotaBene] CHECK CONSTRAINT [FK_RegisterNotaBene_Register_RegisterID]
GO
