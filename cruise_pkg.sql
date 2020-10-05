CREATE OR REPLACE PACKAGE BODY APPS.XXSUB_CRUISE_PKG AS
/******************************************************************************
   NAME:       XXSUB_CRUISE_PKG
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        21-10-2019      jenfri       1. Created this package body.
******************************************************************************/

PROCEDURE vessels (
                          p_vessel_type                in  varchar2,
                          p_vessel_nr                  in  varchar2,
                          p_dtu_vessel                 in  varchar2,
                          p_other_vessel               in  varchar2,
                          p_other_vessel_nr            in  varchar2,
                          p_vessel_brt                 in  varchar2,
                          p_vessel_name                out varchar2,
                          p_brt                        out varchar2 
)
is
--p_brt varchar2(10) := '':
begin
    if ( p_vessel_type = 'DTU' )
    then
      p_vessel_name   := p_dtu_vessel;
      select nvl(xxsub_cruise_pkg.vessel_brt(p_vessel_name),'N') into p_brt from dual;
    else
       p_vessel_name  := p_other_vessel;
       p_brt     := nvl(p_vessel_brt,'N');
    end if;
end;

FUNCTION getRole (p_role_code in varchar2, p_lang in varchar2) return varchar is
 l_role dtu.XXSUB_AQUA_ROLE.role_code%TYPE;

begin
 if (p_lang='da')
 then
   select display_da into l_role from dtu.XXSUB_AQUA_ROLE where upper(role_code) = upper(p_role_code);
 elsif (p_lang='en')
 then   select display_en into l_role from dtu.XXSUB_AQUA_ROLE where upper(role_code) = upper(p_role_code);
  end if;
 return l_role;
 
 exception
 when no_data_found
 then return ''; 
 
 end getRole;

FUNCTION getVesselType (p_type_code in varchar2, p_lang in varchar2) return varchar is
 l_type dtu.XXSUB_VESSEL_TYPE.vessel_type_dk%TYPE;

begin
 if (p_lang='da')
 then
   select vessel_type_dk into l_type from dtu.XXSUB_VESSEL_TYPE where upper(vessel_type_code) = upper(p_type_code);
 elsif (p_lang='en')
 then   select vessel_type_en into l_type from dtu.XXSUB_VESSEL_TYPE where upper(vessel_type_code) = upper(p_type_code);
  end if;
 return l_type;
 
 exception
 when no_data_found
 then return ''; 
 
 end getVesselType;

FUNCTION getVesselInfo (p_vessel in varchar, p_brt out varchar, p_nr out varchar) return number
IS
l_brt varchar2(10);
l_nr  varchar2(10);
BEGIN
  select VESSEL_BRT,VESSEL_NUMBER
  into  l_brt, l_nr 
  from  dtu.XXSUB_VESSEL
  where upper(vessel_name) = upper (p_vessel);

  p_brt := l_brt;
  p_nr :=  l_nr;
  return 0;
  
  exception
  when NO_DATA_FOUND
  then
    p_brt:='';
    p_nr :='';
   return (11);
END getVesselInfo;

FUNCTION getPayout (p_where in varchar2) return number is
v_payout number;
v_sql varchar2(4000);
v_where varchar2(100);
BEGIN
  
  v_sql := 'select nvl(total,0) from xxsub_aqua_rates ';

 -- v_sql := 'select 1 from xxsub_aqua_rates ';

  v_where := ' where rate_code = ''CRUISE_INTERNAL'' '; 

 v_sql := v_sql || 'where ' ||p_where; 
 
 --v_sql :=    'SELECT 1 FROM dual';
  
 EXECUTE IMMEDIATE v_sql INTO v_payout;

 
/*
execute immediate
   'SELECT 1
   FROM dual
   ' INTO v_payout;
*/
 return v_payout;

END getPayOut;
FUNCTION vessel_brt(p_vessel_name in xxsub_vessel.vessel_name%TYPE )return varchar is
brt number;
begin
  select count(*) into brt
  from  XXSUB_VESSEL
  where upper(vessel_name)=upper(p_vessel_name)
  and vessel_brt = '>100';

  if brt  > 0
  then
     return 'Y'; 
  else
     return 'N';
  end if;    
end;  
 


  FUNCTION vessel_type(p_vessel_name in xxsub_vessel.vessel_name%TYPE )return number  is
  l_type number;
  begin 
      
    select case vessel_type
    when '3COM' then 1
    when '4OTHER' then 1
    else 0
    end typ
    into l_type
    from xxsub_vessel
    where vessel_name=p_vessel_name;

return l_type;  
    exception 

   when no_data_found then return 0;
  end;

  PROCEDURE update_cruise_details IS
  BEGIN
    NULL;
  END update_cruise_details;
  
  FUNCTION create_cruise_old (
                    p_part_id            IN xxsub_cruise.part_id%TYPE,
                    p_department         IN xxsub_cruise.department%TYPE,
                    p_arrival_harbour    IN xxsub_cruise.arrival_harbour%TYPE,
                    p_departure_harbour  IN xxsub_cruise.departure_harbour%TYPE,
                    p_departure_datetime IN xxsub_cruise.departure_datetime%TYPE,
                    p_arrival_datetime   IN xxsub_cruise.arrival_datetime%TYPE
                           ) RETURN xxsub_cruise.cruise_id%TYPE is
    v_cruise_id xxsub_cruise.cruise_id%TYPE; 
  BEGIN
    INSERT INTO xxsub_cruise
      (
         part_id 
        ,department
        ,arrival_harbour
        ,departure_harbour
        ,departure_datetime 
        ,arrival_datetime  
)
    VALUES
      (
              p_part_id
             ,p_department
             ,p_arrival_harbour
             ,p_departure_harbour
             ,p_departure_datetime 
             ,p_arrival_datetime
              )
    RETURNING cruise_id INTO v_cruise_id;

    RETURN(v_cruise_id);
end create_cruise_old;  

  PROCEDURE update_cruise_old (p_cruise_id   IN xxsub_cruise.cruise_id%TYPE  
                    ,p_part_id            IN xxsub_cruise.part_id%TYPE
                    ,p_department         IN xxsub_cruise.department%TYPE
                    ,p_arrival_harbour    IN xxsub_cruise.arrival_harbour%TYPE
                    ,p_departure_harbour  IN xxsub_cruise.departure_harbour%TYPE
                    ,p_departure_datetime IN xxsub_cruise.departure_datetime%TYPE
                    ,p_arrival_datetime   IN xxsub_cruise.arrival_datetime%TYPE ) is 
  BEGIN
      UPDATE xxsub_cruise
             set department      = p_department
             ,arrival_harbour    = p_arrival_harbour
             ,departure_harbour  = p_departure_harbour
             ,departure_datetime = p_departure_datetime 
             ,arrival_datetime   = p_arrival_datetime
      WHERE  cruise_id = p_cruise_id;
end update_cruise_old;  

  FUNCTION create_cruise(
     p_part_id            IN xxsub_cruise.part_id%TYPE
    ,p_department         IN xxsub_cruise.department%TYPE
    ,p_arrival_harbour    IN xxsub_cruise.arrival_harbour%TYPE
    ,p_departure_harbour  IN xxsub_cruise.departure_harbour%TYPE
    ,p_departure_datetime IN xxsub_cruise.departure_datetime%TYPE
    ,p_arrival_datetime   IN xxsub_cruise.arrival_datetime%TYPE
    ,p_vessel_brt         IN xxsub_cruise.vessel_brt%TYPE
    ,p_vessel_type        IN xxsub_cruise.vessel_type%TYPE
    ,p_vessel_name        IN xxsub_cruise.vessel_name%TYPE
    ,p_vessel_number      IN xxsub_cruise.vessel_number%TYPE
    ,p_hours_day          IN xxsub_cruise.hours_day%TYPE
    ,p_hours_other        IN xxsub_cruise.hours_other%TYPE
    ,p_role               IN xxsub_cruise.employee_role%TYPE
    ,p_position           IN xxsub_cruise.employee_position%TYPE
    ,p_task               IN xxsub_cruise.task%TYPE
    ,p_cruise_lead        IN xxsub_cruise.cruise_lead%TYPE
    ,p_project            IN xxsub_cruise.project%TYPE
    ,p_lunchbox           IN xxsub_cruise.lunchbox%TYPE
    ,p_purpose            IN xxsub_cruise.purpose%TYPE
   ) RETURN xxsub_cruise.cruise_id%TYPE IS
    v_cruise_id xxsub_cruise.cruise_id%TYPE;
  BEGIN
    INSERT INTO xxsub_cruise
      (
         part_id 
         ,department
         ,arrival_harbour
         ,departure_harbour
         ,departure_datetime 
         ,arrival_datetime 
         ,vessel_brt
         ,vessel_type
         ,vessel_name
         ,vessel_number
         ,hours_day
         ,hours_other
         ,employee_role
         ,employee_position
         ,task
         ,cruise_lead
         ,project
         ,lunchbox)
    VALUES
      (
              p_part_id
              ,p_department
              ,p_arrival_harbour
              ,p_departure_harbour
              ,p_departure_datetime 
              ,p_arrival_datetime  
              ,p_vessel_brt 
              ,p_vessel_type
              ,p_vessel_name
              ,p_vessel_number
              ,p_hours_day
              ,p_hours_other
              ,p_role
              ,p_position
              ,p_task
              ,p_cruise_lead
              ,p_project
              ,p_lunchbox
       )
    RETURNING cruise_id INTO v_cruise_id;

    RETURN(v_cruise_id);
    
end create_cruise;

  PROCEDURE update_cruise (
     p_cruise_id          IN xxsub_cruise.cruise_id%TYPE
    ,p_part_id            IN xxsub_cruise.part_id%TYPE
    ,p_department         IN xxsub_cruise.department%TYPE
    ,p_arrival_harbour    IN xxsub_cruise.arrival_harbour%TYPE
    ,p_departure_harbour  IN xxsub_cruise.departure_harbour%TYPE
    ,p_departure_datetime IN xxsub_cruise.departure_datetime%TYPE
    ,p_arrival_datetime   IN xxsub_cruise.arrival_datetime%TYPE
    ,p_vessel_brt         IN xxsub_cruise.vessel_brt%TYPE
    ,p_vessel_type        IN xxsub_cruise.vessel_type%TYPE
    ,p_vessel_name        IN xxsub_cruise.vessel_name%TYPE
    ,p_vessel_number      IN xxsub_cruise.vessel_number%TYPE
    ,p_hours_day          IN xxsub_cruise.hours_day%TYPE
    ,p_hours_other        IN xxsub_cruise.hours_other%TYPE
    ,p_role               IN xxsub_cruise.employee_role%TYPE
    ,p_position           IN xxsub_cruise.employee_position%TYPE
    ,p_task               IN xxsub_cruise.task%TYPE
    ,p_cruise_lead        IN xxsub_cruise.cruise_lead%TYPE
    ,p_project            IN xxsub_cruise.project%TYPE
    ,p_lunchbox           IN xxsub_cruise.lunchbox%TYPE
    ,p_purpose            IN xxsub_cruise.purpose%TYPE    
    ) AS
    BEGIN
      UPDATE xxsub_cruise
      SET    department         = 'p_department'
            ,arrival_harbour    = p_arrival_harbour
            ,departure_harbour  = p_departure_harbour
            ,departure_datetime = p_departure_datetime
            ,arrival_datetime   = p_arrival_datetime
            ,vessel_brt         = p_vessel_brt
            ,vessel_type        = p_vessel_type
            ,vessel_name        = p_vessel_name
            ,vessel_number      = p_vessel_number
            ,hours_day          = p_hours_day
            ,hours_other        = p_hours_other
            ,employee_role      = p_role
            ,cruise_lead        = p_cruise_lead
            ,project            = p_project
            ,task               = p_task  
            ,lunchbox           = p_lunchbox
            ,purpose            = p_purpose
      WHERE  cruise_id = p_cruise_id;
  END update_cruise;
  procedure build_bonus (
  p_bonus        out varchar
  ,p_bonus2      out varchar
  ,p_lunchbox    in  varchar
  ,p_drawback    in  varchar
  ,p_role        in  varchar
  ,p_vessel      in  varchar
  ,p_vessel_type in  varchar
  ,p_brt         in  number
  ,p_days        in  number
  ,p_hours       in  number 
  )  is
  l_bonus  varchar2(200) :='';
  l_bonus2 varchar2(200) :='';
  begin

    if (to_number(nvl(p_lunchbox,0)) > 0  and p_hours < 17)          then l_bonus := l_bonus || 'LUNCHBOX:'; end if;
    if (p_drawback='Y')          then l_bonus := l_bonus || 'DRAWBACK:'; end if;
    if (p_role='FIELD_INTERNAL') then l_bonus := l_bonus || 'FIELD_INTERNAL:'; end if;
    if (p_role='FIELD_EXTERNAL') then l_bonus := l_bonus || 'FIELD_EXTERNAL:'; end if;

    p_bonus := l_bonus; 

    if (p_role='SKIPPER' and upper(p_vessel) = 'HAVFISKEN' ) then l_bonus2 := l_bonus2 || 'SKIPPER_HAVFISKEN:'; end if;
    if (p_role='MATE'    and upper(p_vessel) = 'HAVFISKEN' ) then l_bonus2 := l_bonus2 || 'MATE_HAVFISKEN:';    end if;
    if (p_role='SKIPPER' and upper(p_vessel) = 'HAVFISKEN' ) then l_bonus2 := l_bonus2 || 'SKIPPER_HAVFISKEN:'; end if;
    if (p_role='MATE'    and upper(p_vessel) = 'HAVFISKEN' ) then l_bonus2 := l_bonus2 || 'MATE_HAVFISKEN:';    end if;

    if (p_role='AC' and upper(p_vessel_TYPE) = 'RESEARCH'  ) then l_bonus2 := l_bonus2 || 'SKIPPER_AC:';        end if;
    if (p_role='AC' and upper(p_vessel_TYPE) = 'RESEARCH'  ) then l_bonus2 := l_bonus2 || 'MATE_AC:';           end if;

    if (p_brt > 100)
    then 
      l_bonus2 := l_bonus2 || 'NIGHT_100:';
    else
      l_bonus2 := l_bonus2 || 'NIGHT:';
    end if;

    p_bonus2 := l_bonus2; 

--    p_bonus   := 'LUNCHBOX:EXTERNAL_FIELD:INTERNAL_FIELD:EXTERNAL_CRUISELEAD:INTERNAL_CRUISELEAD';
--    p_bonus_2 := 'SKIPPER_SMALL:SKIPPER_HAVFISKEN:MATE_HAVFISKEN:MATE_AC:MATE_AC:NIGHT_100:NIGHT';

  end build_bonus;    
                          
  PROCEDURE calc_cruise_jon(
                          p_project                    in  varchar2,
                          p_task                       in  varchar2,
                          p_project_type               in  varchar2,
                          p_departure_datetime         in  date,
                          p_arrival_datetime           in  date,
                          p_role                       in  varchar2,
                          p_drawback_allowance         in  varchar2,
                          p_lunchbox                   in  varchar2,
                          p_dept_harbour               in  varchar2,
                          p_arr_harbour                in  varchar2,
                          p_vessel_type                in  varchar2,
                          p_vessel_nr                  in  varchar2,
                          p_cruise_lead                in  varchar2,
                          p_dtu_vessel                 in  varchar2,
                          p_other_vessel               in  varchar2,
                          p_other_vessel_nr            in  varchar2,
                          p_vessel_brt                 in  varchar2,
                          p_payment_currency_code      in  varchar2,
                          p_exchange_rate              in  number,
                          p_lunchbox_amount            out varchar2,
                          p_drawback_amount            out varchar2,                                                    
                          p_disp_full_days             out varchar2,
                          p_disp_hours_total           out varchar2,                          
                          p_disp_role                  out varchar2,
                          p_disp_project               out varchar2,
                          p_disp_task                  out varchar2,
                          p_disp_project_type          out varchar2,
                          p_disp_vessel_type           out varchar2,
                          p_disp_vessel_nr             out varchar2,                                                    
                          p_disp_brt                   out varchar2,
                          p_disp_dept_harbour          out varchar2,
                          p_disp_arr_harbour           out varchar2,
                          p_disp_cruise_lead           out varchar2,
                          p_bonus                      out varchar2,
                          p_bonus2                     out varchar2) IS

    v_from timestamp;
    v_to   timestamp;
 --   v_vessel_name varchar2(20);
    v_night_payout     NUMBER;
    v_day_payout       NUMBER;
    v_total            NUMBER;
    v_day_default      NUMBER := xxsub_utils_pkg.get_property_num('DEFAULT_TD_PENGE');
    v_night            NUMBER := xxsub_utils_pkg.get_property_num('DEFAULT_NAT_TILLÆG');
    v_rate             NUMBER := P_EXCHANGE_RATE;
    v_lunchbox         NUMBER;
    v_lunch            NUMBER;
    v_disp_hours_total number;
    v_disp_day         number;    
--    p_disp_hours_total number;
    P_DISP_DAY_HOURS   number;

    l_luncbox_amount   number := 57.85;
    l_drawback_amount  number := 80.55;
    
    l_brt              varchar2(1);
        
  BEGIN

    v_from  := to_timestamp(P_DEPARTURE_DATETIME);
    v_to    := to_timestamp(P_ARRIVAL_DATETIME);

     -- Calculate the number of days
    P_DISP_HOURS_TOTAL := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);
    P_DISP_FULL_DAYS   := TRUNC(P_DISP_HOURS_TOTAL/24);  
--    P_DISP_DAY_HOURS   := TRUNC(P_DISP_HOURS_TOTAL/24) * 24;
--    P_DISP_HOURS       := P_DISP_HOURS_TOTAL - P_DISP_DAY_HOURS;
--    P_DISP_DAYS        := P_DISP_FULL_DAYS;
--    P_DISP_NIGHTS      := TRUNC(v_to) - TRUNC(v_from);

    P_DISP_ROLE          := p_role;
    P_DISP_PROJECT       := p_project;
    P_DISP_TASK          := p_task;
    P_DISP_PROJECT_TYPE  := p_project_type;
    P_DISP_VESSEL_TYPE   := p_vessel_type;
    P_DISP_VESSEL_NR     := p_other_vessel_nr;
    P_DISP_CRUISE_LEAD   := p_cruise_lead;

/*
vessels (p_vessel_type,
                          p_vessel_nr,
                          p_dtu_vessel,
                          p_other_vessel,
                          p_other_vessel_nr,
                          p_vessel_brt,
                          p_disp_vessel,
                          p_disp_brt); 

*/

    p_disp_dept_harbour  := p_dept_harbour;
    p_disp_arr_harbour   := p_arr_harbour;

    if ( p_vessel_type = 'DTU' )
    then
      select nvl(xxsub_cruise_pkg.vessel_brt(p_dtu_vessel),'N') into p_disp_brt from dual;
    else
       p_disp_brt     := nvl(p_vessel_brt,'N');
    end if;

    build_bonus(
    p_bonus    => p_bonus,
    p_bonus2   => p_bonus2,
    p_lunchbox => p_lunchbox,
    p_drawback => p_drawback_allowance,
    p_role     => p_role,
    p_vessel   => 'v_vessel_name',
    p_vessel_type => p_vessel_type,
    p_brt =>  100,
    p_days      => P_DISP_FULL_DAYS-1,
    p_hours     => P_DISP_HOURS_TOTAL);

    p_lunchbox_amount := p_lunchbox;

    if (p_lunchbox='Y') 
      then
        p_lunchbox_amount := TO_CHAR(P_DISP_FULL_DAYS*l_luncbox_amount, '999G990D00');
    end if;

    p_drawback_amount := 0;


    if (p_drawback_allowance='Y') 
      then
        p_drawback_amount := TO_CHAR(P_DISP_FULL_DAYS*l_drawback_amount, '999G990D00');
    end if;
    
end calc_cruise_jon;

  PROCEDURE calc_cruise_old(
                          p_payment_currency_code   in  varchar2,
                          p_departure_datetime      in  date,
                          p_arrival_datetime        in  date,
                          p_exchange_rate           in  number,
                          p_role                    in  varchar2,
                          p_project_type            in  varchar2, 
                          p_lunchbox                in  varchar2, 
                          p_lunchbox_amount         out varchar2,                          
                          p_disp_full_days          out varchar2,
                          p_disp_hours              out varchar2,
                          p_disp_days               out varchar2,
                          p_disp_nights             out varchar2,
                          p_role_c                  out varchar2,                          
                          p_project_c               out varchar2                          
                          ) IS      

    v_from timestamp;
    v_to   timestamp;

    v_night_payout  NUMBER;
    v_day_payout    NUMBER;
    v_total         NUMBER;
    v_day_default   NUMBER := xxsub_utils_pkg.get_property_num('DEFAULT_TD_PENGE');
    v_night         NUMBER := xxsub_utils_pkg.get_property_num('DEFAULT_NAT_TILLÆG');
    v_rate          NUMBER := P_EXCHANGE_RATE;
    v_lunchbox      NUMBER;
    v_lunch         NUMBER;
    v_dinner        NUMBER;
    v_day_default_nmkl NUMBER;
    v_disp_hours_total number;
    v_disp_day number;    
    p_disp_hours_total number;
    P_DISP_DAY_HOURS number;    
  BEGIN
    -- Display rates
--    P_DISP_DAILY_RATE := TO_CHAR(v_day_default, '999G990D00');
--    P_DISP_NIGHTLY_RATE := TO_CHAR(v_night, '999G990D00');

    v_from  := to_timestamp(P_DEPARTURE_DATETIME);
    v_to    := to_timestamp(P_ARRIVAL_DATETIME);

--    v_from  := to_timestamp(SYSDATE);
--    v_to    := to_timestamp(SYSDATE +1);

     -- Calculate the number of days
    P_DISP_HOURS_TOTAL := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);
    P_DISP_FULL_DAYS   := TRUNC(P_DISP_HOURS_TOTAL/24);  
    P_DISP_DAY_HOURS   := TRUNC(P_DISP_HOURS_TOTAL/24) * 24;
    P_DISP_HOURS       := P_DISP_HOURS_TOTAL - P_DISP_DAY_HOURS;
    P_DISP_DAYS        := P_DISP_FULL_DAYS;
    P_DISP_NIGHTS      := TRUNC(v_to) - TRUNC(v_from);
    
    P_ROLE_C    := p_role;
    P_PROJECT_C := p_project_type;


--  v_disp_hours_total := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);
--  v_disp_day := EXTRACT(DAY FROM v_to-v_from);

     -- Calculate the number of days
--    P_DISP_HOURS_TOTAL := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);

    -- Currecy conversion into payment currency
/*    IF P_PAYMENT_CURRENCY_CODE != 'DKK' THEN
        v_day_default := (v_day_default  / v_rate) * 100;
        v_night       := (v_night  / v_rate) * 100;
    END IF;
    
    IF P_SETTLEMENT_TYPE = 'T' THEN
      -- Time dagpenge
      IF P_HOUSING_RATE IS NULL THEN
        P_HOUSING_RATE := TO_CHAR(v_night, '999G990D00');
      ELSE
        v_night := NV('P40_HOUSING_RATE');
      END IF;
      
      IF P_HOUSING_NIGHTS IS NULL THEN
        P_HOUSING_NIGHTS := 0;
      END IF;
  
      v_night_payout        := ROUND(v_night * P_HOUSING_NIGHTS,2);
      P_NIGHT_PAYOUT     := TO_CHAR(v_night_payout, '999G990D00');
*/      
--      v_breakfast := (NVL(P_MEALS_BREAKFAST,0) * (v_day_default*0.15));
        v_lunchbox :=   v_disp_day*10;
--      v_lunch     := (NVL(P_MEALS_LUNCH,0) * (v_day_default*0.30));
--      v_dinner    := (NVL(P_MEALS_DINNER,0) * (v_day_default*0.30));    
      
      -- Already payed meals should be substracted
--      v_day_payout := ((P_DISP_FULL_DAYS + P_DISP_HOURS/24) * v_day_default) - (
--                           v_breakfast + v_lunch + v_dinner
--                       );
  
--      P_DAY_PAYOUT       := TO_CHAR(v_day_payout, '999G990D00');
--      P_PAYOUT_TOTAL     := TO_CHAR(v_night_payout + v_day_payout, '999G990D00');
      
      -- Calculate the Meals deductions

      p_lunchbox_amount := null;

      if (p_lunchbox='Y') 
      then
        p_lunchbox_amount := TO_CHAR(v_lunchbox, '999G990D00');
      end if;

        p_lunchbox_amount := TO_CHAR(100, '999G990D00');


--      P_MEALS_LUNCH_AMOUNT     := TO_CHAR(v_lunch, '999G990D00');
--      P_MEALS_DINNER_AMOUNT    := TO_CHAR(v_dinner, '999G990D00');
/*   
    ELSIF  P_SETTLEMENT_TYPE = 'D' THEN
      -- Time dagpenge (25%)
      v_night_payout        := ROUND(NV('P40_HOUSING_RATE') * P_HOUSING_NIGHTS,2);
      P_NIGHT_PAYOUT     := TO_CHAR(v_night_payout, '999G990D00');
      v_day_payout          := ROUND((v_day_default * 0.25) * P_DISP_DAYS,2);
      P_DAY_PAYOUT       := TO_CHAR(v_day_payout, '999G990D00');
      P_PAYOUT_TOTAL     := TO_CHAR(NVL(v_night_payout,0) + v_day_payout, '999G990D00');
      
    ELSIF  P_SETTLEMENT_TYPE = 'A' THEN
      -- Aftalt diæt
      P_NIGHT_PAYOUT    := TO_CHAR(0, '999G990D00');
      
      v_day_payout          := ROUND(NV('P40_FOOD_RATE') * P_DISP_DAYS,2);
      P_DAY_PAYOUT       := TO_CHAR(v_day_payout, '999G990D00');
      P_PAYOUT_TOTAL     := TO_CHAR(NVL(v_night_payout,0) + v_day_payout, '999G990D00');
    
    END IF;
*/    
end calc_cruise_old;


/*

  PROCEDURE calc_per_diem(p_submitter_type_code     in varchar2,
                          p_payment_currency_code   in varchar2,
                          p_settlement_type         in varchar2,
                          p_departure_datetime      in date,
                          p_return_datetime         in date,
                          p_exchange_rate           in number,
                          p_disp_daily_rate         out varchar2,
                          p_disp_nightly_rate       out varchar2,
                          p_disp_hours              out varchar2,
                          p_disp_hours_total        out varchar2,
                          p_disp_full_days          out varchar2,
                          p_disp_day_hours          out varchar2,
                          p_disp_days               out varchar2,
                          p_disp_nights             out varchar2,
                          p_housing_nights          in out varchar2,
                          p_housing_rate            out varchar2,
                          p_night_payout            out varchar2,
                          p_day_payout              out varchar2,
                          p_payout_total            out varchar2,
                          p_meals_breakfast         in varchar2,
                          p_meals_lunch             in varchar2,
                          p_meals_dinner            in varchar2,
                          p_meals_breakfast_amount  out varchar2,
                          p_meals_lunch_amount      out varchar2,
                          p_meals_dinner_amount     out varchar2) IS      
    v_from timestamp := to_timestamp(P_DEPARTURE_DATETIME);
    v_to   timestamp := to_timestamp(P_RETURN_DATETIME);  
    v_night_payout  NUMBER;
    v_day_payout    NUMBER;
    v_total         NUMBER;
    v_day_default   NUMBER := xxsub_utils_pkg.get_property_num('DEFAULT_TD_PENGE');
    v_night         NUMBER := xxsub_utils_pkg.get_property_num('DEFAULT_NAT_TILLÆG');
    v_rate          NUMBER := P_EXCHANGE_RATE;
    v_breakfast     NUMBER;
    v_lunch         NUMBER;
    v_dinner        NUMBER;
    v_day_default_nmkl NUMBER;
  BEGIN
  
    -- Handle NMKL, dispatch the calculation to the NMKL function
    IF p_submitter_type_code = 'NMKL' THEN
      calc_per_diem_nmkl( p_submitter_type_code,
                          p_payment_currency_code,
                          p_settlement_type,
                          p_departure_datetime,
                          p_return_datetime,
                          p_exchange_rate,
                          p_disp_daily_rate,
                          p_disp_nightly_rate,
                          p_disp_hours,
                          p_disp_hours_total,
                          p_disp_full_days,
                          p_disp_day_hours,
                          p_disp_days,
                          p_disp_nights,
                          p_housing_nights,
                          p_housing_rate,
                          p_night_payout,
                          p_day_payout,
                          p_payout_total,
                          p_meals_breakfast,
                          p_meals_lunch,
                          p_meals_dinner,
                          p_meals_breakfast_amount,
                          p_meals_lunch_amount,
                          p_meals_dinner_amount);
      Return;
    END IF;
    
    -- Display rates
    P_DISP_DAILY_RATE := TO_CHAR(v_day_default, '999G990D00');
    P_DISP_NIGHTLY_RATE := TO_CHAR(v_night, '999G990D00');
    
     -- Calculate the number of days
    P_DISP_HOURS_TOTAL := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);
    logger.log('P_DISP_HOURS_TOTAL:' || P_DISP_HOURS_TOTAL);
    P_DISP_FULL_DAYS   := TRUNC(P_DISP_HOURS_TOTAL/24);  
    P_DISP_DAY_HOURS   := TRUNC(P_DISP_HOURS_TOTAL/24) * 24;
    P_DISP_HOURS       := P_DISP_HOURS_TOTAL - P_DISP_DAY_HOURS;
    P_DISP_DAYS        := P_DISP_FULL_DAYS;
    P_DISP_NIGHTS      := TRUNC(v_to) - TRUNC(v_from);
        
    -- Currecy conversion into payment currency
    IF P_PAYMENT_CURRENCY_CODE != 'DKK' THEN
        v_day_default := (v_day_default  / v_rate) * 100;
        v_night       := (v_night  / v_rate) * 100;
    END IF;
    
    IF P_SETTLEMENT_TYPE = 'T' THEN
      -- Time dagpenge
      IF P_HOUSING_RATE IS NULL THEN
        P_HOUSING_RATE := TO_CHAR(v_night, '999G990D00');
      ELSE
        v_night := NV('P40_HOUSING_RATE');
      END IF;
      
      IF P_HOUSING_NIGHTS IS NULL THEN
        P_HOUSING_NIGHTS := 0;
      END IF;
  
      v_night_payout        := ROUND(v_night * P_HOUSING_NIGHTS,2);
      P_NIGHT_PAYOUT     := TO_CHAR(v_night_payout, '999G990D00');
      
      v_breakfast := (NVL(P_MEALS_BREAKFAST,0) * (v_day_default*0.15));
      v_lunch     := (NVL(P_MEALS_LUNCH,0) * (v_day_default*0.30));
      v_dinner    := (NVL(P_MEALS_DINNER,0) * (v_day_default*0.30));    
      
      -- Already payed meals should be substracted
      v_day_payout := ((P_DISP_FULL_DAYS + P_DISP_HOURS/24) * v_day_default) - (
                           v_breakfast + v_lunch + v_dinner
                       );
  
      P_DAY_PAYOUT       := TO_CHAR(v_day_payout, '999G990D00');
      P_PAYOUT_TOTAL     := TO_CHAR(v_night_payout + v_day_payout, '999G990D00');
      
      -- Calculate the Meals deductions
      P_MEALS_BREAKFAST_AMOUNT := TO_CHAR(v_breakfast, '999G990D00');
      P_MEALS_LUNCH_AMOUNT     := TO_CHAR(v_lunch, '999G990D00');
      P_MEALS_DINNER_AMOUNT    := TO_CHAR(v_dinner, '999G990D00');
   
    ELSIF  P_SETTLEMENT_TYPE = 'D' THEN
      -- Time dagpenge (25%)
      v_night_payout        := ROUND(NV('P40_HOUSING_RATE') * P_HOUSING_NIGHTS,2);
      P_NIGHT_PAYOUT     := TO_CHAR(v_night_payout, '999G990D00');
      v_day_payout          := ROUND((v_day_default * 0.25) * P_DISP_DAYS,2);
      P_DAY_PAYOUT       := TO_CHAR(v_day_payout, '999G990D00');
      P_PAYOUT_TOTAL     := TO_CHAR(NVL(v_night_payout,0) + v_day_payout, '999G990D00');
      
    ELSIF  P_SETTLEMENT_TYPE = 'A' THEN
      -- Aftalt diæt
      P_NIGHT_PAYOUT    := TO_CHAR(0, '999G990D00');
      
      v_day_payout          := ROUND(NV('P40_FOOD_RATE') * P_DISP_DAYS,2);
      P_DAY_PAYOUT       := TO_CHAR(v_day_payout, '999G990D00');
      P_PAYOUT_TOTAL     := TO_CHAR(NVL(v_night_payout,0) + v_day_payout, '999G990D00');
    
    END IF;
*/


  PROCEDURE calc_cruise (
         p_departure_datetime in  date
        ,p_arrival_datetime   in  date
        ,p_position           in  varchar2
        ,p_cruise_lead        in varchar2 
        ,p_DISP_cruise_lead   out varchar2 
        ,p_disp_lead_payout   out varchar2                                   
        ,p_disp_position      out varchar2
        ,p_role               in  varchar2
        ,p_disp_role          out  varchar2
        ,p_disp_full_days     out varchar2
        ,p_disp_nights        out varchar2
        ,p_disp_hours         out varchar2                          
        ,p_disp_days          out varchar2
        ,p_total              out varchar2
        ,p_disp_vessel_type   out varchar2
        ,p_disp_nr            out varchar2
        ,p_vessel_nr          in  varchar2
        ,p_vessel_type        in  varchar2                                 
        ) IS
        
    v_from timestamp;
    v_to   timestamp;
    p_disp_hours_total varchar2(5);    
    v_full_days   varchar2(5);    
    v_day_hours   varchar2(5);    
    v_hours       varchar2(5);    
    v_nights      varchar2(5);   
    
    V_DISP_DAY_HOURS varchar2(5); 
                          
BEGIN
    v_from  := to_timestamp(P_DEPARTURE_DATETIME);
    v_to    := to_timestamp(P_ARRIVAL_DATETIME);

    p_disp_vessel_type := p_vessel_type;
    p_disp_nr := p_vessel_nr;

 --   logger.log('CAL_CRUISE' || p_departure_datetime);

     -- Calculate the number of days
    P_DISP_HOURS_TOTAL := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);
    P_DISP_FULL_DAYS   := TRUNC(P_DISP_HOURS_TOTAL/24);
    V_DISP_DAY_HOURS   := TRUNC(P_DISP_HOURS_TOTAL/24) * 24;
    P_DISP_HOURS       := P_DISP_HOURS_TOTAL - V_DISP_DAY_HOURS;
    P_DISP_DAYS        := P_DISP_FULL_DAYS;
    P_DISP_NIGHTS      := TRUNC(v_to) - TRUNC(v_from);

p_disp_role := p_role; 
p_disp_position := p_position; 
p_disp_cruise_lead := p_cruise_lead;
    if (p_position = 'AC' ) 
    then 
--      p_disp_vessel_type := p_vessel_type; 
      p_total := getPayout ( ' rate_code=''CRUISE_INTERNAL'' ');
    elsif  (p_position = 'TL' ) 
    then 
--      p_disp_vessel_type := 'def'; 
      p_total := getPayout ( ' rate_code=''CRUISE_EXTERNAL'' ');
    else p_total := ''; 
    end if; 
if ( nvl(p_cruise_lead,'x') <> 'x' )
then
p_disp_lead_payout := getPayout ( ' rate_code='''||p_cruise_lead||''' ');
end if;
END calc_cruise;

  PROCEDURE calc_cruise_org (
         p_project                    in  varchar2
        ,p_task                       in  varchar2
        ,p_project_type               in  varchar2
        ,p_departure_datetime         in  date
        ,p_arrival_datetime           in  date
        ,p_role                       in  varchar2
        ,p_lunchbox                   in  varchar2
        ,p_dept_harbour               in  varchar2
        ,p_arr_harbour                in  varchar2
        ,p_vessel_type                in  varchar2
        ,p_vessel_nr                  in  varchar2                          
        ,p_cruise_lead                in  varchar2
        ,p_dtu_vessel                 in  varchar2
        ,p_other_vessel               in  varchar2
        ,p_other_vessel_nr            in  varchar2
        ,p_vessel_brt                 in  varchar2
        ,p_payment_currency_code      in  varchar2
        ,p_exchange_rate              in  number
        ,p_lunchbox_amount            out varchar2
        ,p_disp_role                  out varchar2
        ,p_disp_project               out varchar2
        ,p_disp_task                  out varchar2                          
        ,p_disp_vessel_type           out varchar2                          
        ,p_disp_vessel_nr             out varchar2                          
        ,p_disp_brt                   out varchar2
        ,p_disp_dept_harbour          out varchar2
        ,p_disp_arr_harbour           out varchar2
        ,p_disp_cruise_lead           out varchar2
        ,p_disp_full_days             out varchar2
        ,p_disp_nights                out varchar2
        ,p_disp_hours                 out varchar2                          
        ,p_disp_days                  out varchar2                          
        ,p_disp_day_hours             out varchar2                          
        ,p_bonus                      out varchar2
        ,p_bonus2                     out varchar2) IS
    v_from timestamp;
    v_to   timestamp;
    p_disp_hours_total varchar2(5);    
    v_full_days   varchar2(5);    
    v_day_hours   varchar2(5);    
    v_hours       varchar2(5);    
    v_nights      varchar2(5);    
                          
BEGIN
    v_from  := to_timestamp(P_DEPARTURE_DATETIME);
    v_to    := to_timestamp(P_ARRIVAL_DATETIME);

     -- Calculate the number of days
    P_DISP_HOURS_TOTAL := (EXTRACT(DAY FROM v_to-v_from) * 24) + EXTRACT(HOUR FROM v_to-v_from);
    P_DISP_FULL_DAYS   := TRUNC(P_DISP_HOURS_TOTAL/24);
    P_DISP_DAY_HOURS   := TRUNC(P_DISP_HOURS_TOTAL/24) * 24;
    P_DISP_HOURS       := P_DISP_HOURS_TOTAL - P_DISP_DAY_HOURS;
    P_DISP_DAYS        := P_DISP_FULL_DAYS;
    P_DISP_NIGHTS      := TRUNC(v_to) - TRUNC(v_from);

    if ( p_vessel_type = 'DTU' )
    then
      select nvl(xxsub_cruise_pkg.vessel_brt(p_dtu_vessel),'N') into p_disp_brt from dual;
    else
       p_disp_brt     := nvl(p_vessel_brt,'N');
    end if;

-- display results REMOVE IN PROD
/*
    P_DISP_ROLE          := p_role;
    P_DISP_PROJECT       := p_project;
    P_DISP_TASK          := p_task;
    P_DISP_VESSEL_TYPE   := p_vessel_type;
    P_DISP_VESSEL_NR     := p_other_vessel_nr;
    P_DISP_CRUISE_LEAD   := p_cruise_lead;
*/
/*
    if ( p_vessel_type = 'DTU' )
    then
      select nvl(xxsub_cruise_pkg.vessel_brt(p_dtu_vessel),'N') into p_disp_brt from dual;
    else
       p_disp_brt     := nvl(p_vessel_brt,'N');
    end if;
*/
END calc_cruise_org;                          

  PROCEDURE get_address (
    p_address  out  varchar2
    ,p_zip     out  varchar2
    ,p_country out  varchar2
    ) is                       
  BEGIN
    p_address := 'Løvdalsvej 8';
    p_zip     := '3200';
    p_country := 'DK';
  END get_address;


END XXSUB_CRUISE_PKG;
/