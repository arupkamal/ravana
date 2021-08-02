CREATE OR REPLACE FUNCTION collect_task (IN_clustername varchar(100), IN_nodename varchar(100))
RETURNS mappedtasks
LANGUAGE plpgsql
AS
$$
DECLARE 
	task_uid UUID;
	task_row mappedtasks;
BEGIN
	SELECT taskuid INTO task_uid FROM mappedtasks 
		WHERE status='Ready' AND clustername=IN_clustername LIMIT 1 FOR UPDATE;
	
	UPDATE mappedtasks SET nodename=IN_nodename, collected = CURRENT_TIMESTAMP, status='Running' 
		WHERE taskuid=task_uid;
	
	SELECT * INTO task_row FROM mappedtasks 
		WHERE taskuid=task_uid;
	
	RETURN task_row;
END
$$;



CREATE OR REPLACE FUNCTION submit_task (IN_task_uid UUID, IN_results TEXT)
RETURNS mappedtasks
LANGUAGE plpgsql
AS
$$
DECLARE 
	task_row mappedtasks;
BEGIN
	UPDATE mappedtasks SET mappedresults=IN_results, completed = CURRENT_TIMESTAMP, status='Done', progress=1 
		WHERE taskuid=IN_task_uid;
	
	SELECT * INTO task_row FROM mappedtasks WHERE taskuid=IN_task_uid;
	
	RETURN task_row;
END
$$;


CREATE OR REPLACE FUNCTION job_stats (IN_clustername varchar(100))
RETURNS TABLE (task text,
			   job_status varchar,
			   count_of_jobs bigint
	)
LANGUAGE plpgsql
AS
$$
DECLARE 
	task_row mappedtasks;
BEGIN
	RETURN QUERY SELECT * FROM 
	((SELECT CONCAT(mappedrfunction, chr(10), taskid, chr(10), nodename) AS task, status AS job_status, COUNT(taskuid) AS count_of_jobs FROM mappedtasks
	WHERE clustername=IN_clustername and status <> 'Closed'
	GROUP BY nodename, taskid, mappedrfunction, status ORDER BY taskid DESC)
	UNION
	(SELECT CONCAT(mappedrfunction, chr(10), taskid) AS task, status AS job_status, COUNT(taskuid) AS count_of_jobs FROM mappedtasks
	WHERE clustername=IN_clustername and status = 'Closed'
	GROUP BY taskid, mappedrfunction, status ORDER BY taskid DESC LIMIT 2)) AS T;
END
$$;