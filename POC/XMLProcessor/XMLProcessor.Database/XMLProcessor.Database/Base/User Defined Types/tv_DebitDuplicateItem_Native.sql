﻿CREATE TYPE [Base].[tv_DebitDuplicateItem_Native] AS TABLE
(
	DplctItmId VARCHAR(MAX)				NULL
	,DbDplctStatus VARCHAR(MAX)			NULL
	,DbtFirstPresented VARCHAR(MAX)		NULL
	,MmbId VARCHAR(MAX)					NULL
	,OriginalCaptureDate VARCHAR(MAX)	NULL
	,OriginalSource VARCHAR(MAX)		NULL
	,DbtItm_Id BIGINT PRIMARY KEY NONCLUSTERED
)WITH(MEMORY_OPTIMIZED = ON);
GO