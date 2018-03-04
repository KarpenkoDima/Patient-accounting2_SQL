SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Address](
	[AddressID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[Region] [nchar](50) NULL,
	[Country] [nchar](50) NULL,
	[City] [nvarchar](100) NOT NULL,
	[AdminDivisionID] [int] NOT NULL,
	[TypeStreetID] [int] NULL,
	[NameStreet] [nvarchar](100) NULL,
	[NumberHouse] [nvarchar](10) NULL,
	[NumberApartment] [nvarchar](10) NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Address_AddressID] PRIMARY KEY CLUSTERED 
(
	[AddressID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Address]  WITH CHECK ADD  CONSTRAINT [FK_Address_AdminDivision_AdminDivisionID] FOREIGN KEY([AdminDivisionID])
REFERENCES [dbo].[AdminDivision] ([AdminDivisionID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Address] CHECK CONSTRAINT [FK_Address_AdminDivision_AdminDivisionID]
GO

ALTER TABLE [dbo].[Address]  WITH CHECK ADD  CONSTRAINT [FK_Address_Customer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customer] ([CustomerID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Address] CHECK CONSTRAINT [FK_Address_Customer_CustomerID]
GO

ALTER TABLE [dbo].[Address]  WITH CHECK ADD  CONSTRAINT [FK_Address_TypeStreet_TypeStreetID] FOREIGN KEY([TypeStreetID])
REFERENCES [dbo].[TypeStreet] ([TypeStreetID])
ON UPDATE CASCADE
ON DELETE SET DEFAULT
GO

ALTER TABLE [dbo].[Address] CHECK CONSTRAINT [FK_Address_TypeStreet_TypeStreetID]
GO

ALTER TABLE [dbo].[Address] ADD  CONSTRAINT [DF_Address_CityName]  DEFAULT ('Славянск') FOR [City]
GO

ALTER TABLE [dbo].[Address] ADD  CONSTRAINT [DF_Address_AdminDivisionID]  DEFAULT ((5)) FOR [AdminDivisionID]
GO

ALTER TABLE [dbo].[Address] ADD  CONSTRAINT [DF_Address_TypeStreetID]  DEFAULT ((172)) FOR [TypeStreetID]
GO

ALTER TABLE [dbo].[Address] ADD  CONSTRAINT [DF_Address_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
