SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Invalid_BenefitsCategory](
	[invID] [int] NOT NULL,
	[BenefitsID] [int] NOT NULL,
 CONSTRAINT [PK_Invalid_BenefitsCategory] PRIMARY KEY CLUSTERED 
(
	[invID] ASC,
	[BenefitsID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Invalid_BenefitsCategory]  WITH CHECK ADD  CONSTRAINT [FK_Invalid_BenefitsCategory_BenefitsCategory_BenefitsCategoryID] FOREIGN KEY([BenefitsID])
REFERENCES [dbo].[BenefitsCategory] ([BenefitsCategoryID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Invalid_BenefitsCategory] CHECK CONSTRAINT [FK_Invalid_BenefitsCategory_BenefitsCategory_BenefitsCategoryID]
GO

ALTER TABLE [dbo].[Invalid_BenefitsCategory]  WITH CHECK ADD  CONSTRAINT [FK_Invalid_BenefitsCategory_Invalid_InvalidID] FOREIGN KEY([invID])
REFERENCES [dbo].[Invalid] ([InvalidID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Invalid_BenefitsCategory] CHECK CONSTRAINT [FK_Invalid_BenefitsCategory_Invalid_InvalidID]
GO
