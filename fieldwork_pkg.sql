CREATE OR REPLACE PACKAGE BODY APPS.xxsub_fieldwork_pkg AS
/******************************************************************************
   NAME:       xxsub_fieldwork_pkg
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23-07-2020      jenfri       1. Created this package body.
******************************************************************************/

/*
FUNCTION getFieldRate (p_role in varchar, p_position in varchar) return number
is
l_rate xxsub_aqua_rates.total%TYPE;
begin

  select nvl(xar.total,0)
  into l_rate
  from xxsub_aqua_rates xar
  where xar.rate_code = p_role
  and   xar.eligible=p_position;

  return l_rate;
  
  exception
    when no_data_found then 
      return 0;
end getFieldRate;  
*/

PROCEDURE getFieldRate (p_role in varchar, p_position in varchar, 
                        p_fieldrate out number, p_drawbackrate out number, p_lunchboxrate out number )
is

l_rate xxsub_aqua_rates.total%TYPE;
begin
  begin
    select nvl(xar.total,0)
    into p_fieldrate
    from xxsub_aqua_rates xar
    where xar.rate_code = p_role
    and   xar.eligible=p_position;

  exception
    when no_data_found then 
      p_fieldrate := 0;
   end;

  begin
    select nvl(xar.total,0)
    into p_drawbackrate 
    from xxsub_aqua_rates xar
    where xar.rate_code = 'DRAWBACK';
--    and   xar.eligible=p_position;
  
    exception
    when no_data_found then 
     p_drawbackrate :=0;
  end;

  begin
    select nvl(xar.total,0)
    into p_lunchboxrate 
    from xxsub_aqua_rates xar
    where xar.rate_code = 'LUNCH';
--    and   xar.eligible=p_position;
  
    exception
    when no_data_found then 
    p_lunchboxrate := 0;
  end;  
end getFieldRate;  


PROCEDURE calc_fieldwork (
     p_project_type      in  varchar2
    ,p_start_datetime    in  date
    ,p_end_datetime      in  date
    ,p_project           in  varchar2
    ,p_task              in  varchar2
    ,p_position          in  varchar2
    ,p_role              in  varchar2
    ,p_leadamount        out varchar2  
    ,p_totamount         out varchar2
    ,p_drawbackamount    out varchar2
    ,p_lunchboxamount    out varchar2
    ,p_lunchbox          in  varchar2
    ,p_disp_full_days    out varchar2
    ,p_disp_hours_total  out varchar2
    ,p_title             out varchar2
) is
    v_from timestamp  := to_timestamp(P_START_DATETIME);
    v_to   timestamp  := to_timestamp(P_END_DATETIME);
    v_DISP_HOURS_TOTAL varchar2(30);
    v_DISP_FULL_DAYS   varchar2(30);
    v_DISP_DAY_HOURS   varchar2(30);    
    v_DISP_HOURS       varchar2(30);
    
    l_lunchboxamount number;
    l_leadamount     number;
    l_drawbackamount number;
    l_totamount      number; 
  BEGIN
     -- Calculate the number of days
    V_DISP_HOURS_TOTAL := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);
    V_DISP_FULL_DAYS   := TRUNC(V_DISP_HOURS_TOTAL/24);
    V_DISP_DAY_HOURS   := TRUNC(V_DISP_HOURS_TOTAL/24) * 24;    
    V_DISP_HOURS       := V_DISP_HOURS_TOTAL - V_DISP_DAY_HOURS;

    p_disp_full_days   := V_DISP_FULL_DAYS;
    p_disp_hours_total := V_DISP_HOURS;

    P_TITLE := p_position ||' '|| p_role;
    
--    p_leadamount      := apps.xxsub_fieldwork_pkg.getFieldRate( p_role, p_position);

--    apps.xxsub_fieldwork_pkg.
    getFieldRate( p_role, p_position, l_leadamount ,l_drawbackamount, l_lunchboxamount  );
    
    p_leadamount     := TO_CHAR(l_leadamount    , '999G990D00');
    p_drawbackamount := TO_CHAR(l_drawbackamount, '999G990D00');
    p_lunchboxamount := TO_CHAR(l_lunchboxamount, '999G990D00');

    l_totamount := (l_leadamount * p_disp_full_days) +l_drawbackamount +  l_lunchboxamount;
    p_totamount := TO_CHAR(l_totamount, '999G990D00');

    
END calc_fieldwork;

  FUNCTION create_fieldwork (
     p_part_id            IN xxsub_fieldwork.part_id%TYPE
    ,p_department         IN xxsub_fieldwork.department%TYPE
    ,p_project            IN xxsub_fieldwork.project%TYPE
    ,p_task               IN xxsub_fieldwork.task%TYPE
    ,p_drawback_amount    IN xxsub_fieldwork.drawback_allowance%TYPE
    ,p_lunchbox_amount    IN xxsub_fieldwork.lunchbox_amount%TYPE
    ,p_payout_total       IN xxsub_fieldwork.payout_total%TYPE
    ,p_position           IN xxsub_fieldwork.employee_position%TYPE
    ,p_role               IN xxsub_fieldwork.employee_role%TYPE                                            
    ,p_start_datetime     IN xxsub_fieldwork.start_datetime%TYPE
    ,p_end_datetime       IN xxsub_fieldwork.end_datetime%TYPE
    ,p_purpose            IN xxsub_fieldwork.purpose%TYPE
    ,p_hours_day          IN xxsub_fieldwork.hours_day%TYPE
    ,p_hours_other        IN xxsub_fieldwork.hours_other%TYPE
  ) RETURN xxsub_fieldwork.fieldwork_id%TYPE  is
    v_fieldwork_id xxsub_fieldwork.fieldwork_id%TYPE;
    
    l_lunchboxrate   number;
    l_leadrate       number;
    l_drawbackrate   number;
    
   BEGIN
   
    getFieldRate( p_role, p_position, l_leadrate ,l_drawbackrate, l_lunchboxrate );

    INSERT INTO xxsub_fieldwork
    (
        part_id
       ,department
       ,project
       ,task
       ,employee_position
       ,employee_role
       ,drawback_allowance
       ,lunchbox_amount
       ,payout_total       
       ,start_datetime 
       ,end_datetime
       ,purpose
       ,hours_day
       ,hours_other
       ,fieldleadrate
       ,LUNCHBOXRATE
       ,drawbackrate       
    )
    VALUES
    (
        p_part_id
       ,p_department
       ,p_project
       ,p_task
       ,p_position
       ,p_role
       ,p_drawback_amount
       ,p_lunchbox_amount
       ,p_payout_total
       ,p_start_datetime 
       ,p_end_datetime
       ,p_purpose
       ,p_hours_day
       ,p_hours_other
       ,l_leadrate
       ,l_lunchboxrate
       ,l_drawbackrate
    )
    RETURNING fieldwork_id INTO v_fieldwork_id;
    
    return v_fieldwork_id;
    
   END create_fieldwork;
  
  PROCEDURE update_fieldwork (p_fieldwork_id   IN xxsub_fieldwork.fieldwork_id%TYPE 
    ,p_part_id            IN xxsub_fieldwork.part_id%TYPE
    ,p_department         IN xxsub_fieldwork.department%TYPE
    ,p_project            IN xxsub_fieldwork.project%TYPE
    ,p_task               IN xxsub_fieldwork.task%TYPE
    ,p_drawback_amount    IN xxsub_fieldwork.drawback_allowance%TYPE
    ,p_lunchbox_amount    IN xxsub_fieldwork.lunchbox_amount%TYPE
    ,p_payout_total       IN xxsub_fieldwork.payout_total%TYPE
    ,p_position           IN xxsub_fieldwork.employee_position%TYPE 
    ,p_role               IN xxsub_fieldwork.employee_role%TYPE                                                                   
    ,p_start_datetime     IN xxsub_fieldwork.start_datetime%TYPE
    ,p_end_datetime       IN xxsub_fieldwork.end_datetime%TYPE
    ,p_purpose            IN xxsub_fieldwork.purpose%TYPE
    ,p_hours_day          IN xxsub_fieldwork.hours_day%TYPE
    ,p_hours_other        IN xxsub_fieldwork.hours_other%TYPE
    
    ) is
  BEGIN
      UPDATE xxsub_fieldwork
             set department   = p_department
             ,project         = p_project
             ,task            = p_task
             ,drawback_allowance = p_drawback_amount
             ,lunchbox_amount = p_lunchbox_amount
             ,payout_total    = p_payout_total
             ,employee_position = p_position
             ,employee_role   = p_role             
             ,start_datetime  = p_start_datetime 
             ,end_datetime    = p_end_datetime
             ,purpose         = p_purpose
             ,hours_day       = p_hours_day
             ,hours_other     = p_hours_other
      WHERE  fieldwork_id     = p_fieldwork_id;
  END update_fieldwork;

                          
END xxsub_fieldwork_pkg;
/