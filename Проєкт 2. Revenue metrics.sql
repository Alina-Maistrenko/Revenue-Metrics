
with montly_revenue as ( 
/* Calculate monthly revenue for each user */
select 
		date(date_trunc('month',
	payment_date)) as payment_month
	, user_id
	, game_name
	, sum(revenue_amount_usd) as total_revenue
from
	project.games_payments gp
group by
	payment_month
	, user_id
	, game_name 
),
	 paid_months as (
select 
	 user_id
	, game_name
	, total_revenue
	, payment_month
	
/* Find the previous and next calendar months for each payment */
	, date(payment_month - interval '1' month) as prev_calendar_month
	, date (payment_month + interval '1 month') as next_calendar_month
					
/* Find the previous and next payment months for each users*/
	, lag(payment_month) over (partition by user_id order by payment_month) as prev_paid_month
	, lead(payment_month) over (partition by user_id order by payment_month) as next_paid_month
	
/* Find the previous month's revenue for the user*/
	, lag(total_revenue) over(partition by user_id order by payment_month) as previous_month_revenue
from
	montly_revenue
),
	metrics as (
select 
	 user_id
	, game_name
	, payment_month
	, total_revenue
	
/* New Monthly Recurring Revenue (New MRR) - revenue from new users*/
	, case
								when prev_paid_month is null
									then total_revenue
	end as new_MRR
	
/* Count new paid users*/
	, case 
								when prev_paid_month is null
									then 1
	end as new_paid_users
	
/* Count of churned users*/
	, case
								when next_paid_month is null
		or next_paid_month != next_calendar_month
									then 1
	end as churn_users
	
/* Count of churned revenue*/
	, case
								when next_paid_month is null
		or next_paid_month != next_calendar_month
									then total_revenue
	end as churn_revenue
	
/* Expansion MRR: additional revenue from existing users who increased spending*/
	, case
								when prev_paid_month = prev_calendar_month
		and total_revenue > previous_month_revenue
									then total_revenue - previous_month_revenue
	end as expansion_MRR
	
/* Contraction MRR: revenue decrease from users who paid less this month*/
	, case
								when prev_paid_month = prev_calendar_month
		and total_revenue < previous_month_revenue
									then total_revenue - previous_month_revenue
	end as contraction_MRR
from
	paid_months
)
select
m.*
, gpu.language
, gpu. has_older_device_model
, gpu.age
from
	metrics as m
/* Join additional user attributes (language, device, age)*/
left join project.games_paid_users gpu on
	m.user_id = gpu.user_id
									
							
							

							
							
					