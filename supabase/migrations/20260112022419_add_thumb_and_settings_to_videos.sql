
ALTER TABLE public.videos 
ADD COLUMN thumb text NULL,
ADD COLUMN settings jsonb NULL;
;
