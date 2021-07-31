-- #############################################################
-- #    MAKE SURE THAT YOU ARE CONNECTED TO RAVANA DATABASE    #
-- #############################################################

--DROP TABLE IF EXISTS public.clusters;
--DROP TABLE IF EXISTS public.mappedtasks;
--DROP TABLE IF EXISTS public.nodes;
--DROP TABLE IF EXISTS public.logs;


CREATE TABLE public.clusters
(
    clustername character varying(100) COLLATE pg_catalog."default" NOT NULL,
    createdby character varying(50) COLLATE pg_catalog."default" NOT NULL,
    createdon timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rfunctions text COLLATE pg_catalog."default",
    robjects text COLLATE pg_catalog."default",
    CONSTRAINT clusters_pkey PRIMARY KEY (clustername)
);



CREATE TABLE public.mappedtasks
(
    taskid bigint NOT NULL,
    clustername character varying(100) COLLATE pg_catalog."default",
    taskseq bigint NOT NULL,
    mappedrfunction character varying(100) COLLATE pg_catalog."default" NOT NULL,
    mappedparameters text COLLATE pg_catalog."default",
    mappedresults text COLLATE pg_catalog."default",
    createdby character varying(50) COLLATE pg_catalog."default" NOT NULL,
    createdon timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nodename character varying(100) COLLATE pg_catalog."default",
    status character varying(20) COLLATE pg_catalog."default" DEFAULT 'Ready'::character varying,
    progress double precision DEFAULT 0,
    collected timestamp without time zone,
    completed timestamp without time zone
);



CREATE TABLE public.nodes
(
    nodename character varying(100) COLLATE pg_catalog."default" NOT NULL,
    osname character varying(50) COLLATE pg_catalog."default" NOT NULL,
    osversion character varying(50) COLLATE pg_catalog."default" NOT NULL,
    speed real NOT NULL DEFAULT '1'::real,
    machinetype character varying(50) COLLATE pg_catalog."default" NOT NULL,
    heartbeat timestamp without time zone,
    memtotal real NOT NULL,
    memfree real NOT NULL,
    cores integer NOT NULL,
    CONSTRAINT nodes_pkey PRIMARY KEY (nodename)
);




CREATE TABLE public.logs
(
    msgid serial NOT NULL,
    createdon timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    clustername character varying(100) COLLATE pg_catalog."default" NOT NULL,
    nodename character varying(100) COLLATE pg_catalog."default" NOT NULL,
    msgtype character varying(50) COLLATE pg_catalog."default" NOT NULL,
    msg text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT logs_pkey PRIMARY KEY (msgid)
);



ALTER TABLE public.clusters OWNER to postgres;
ALTER TABLE public.mappedtasks  OWNER to postgres;
ALTER TABLE public.nodes OWNER to postgres;
ALTER TABLE public.logs OWNER to postgres;