# Get users with elevated privledges

get-adgroupmember 'domain admins' | select name,samaccountname
get-adgroupmember 'enterprise admins' | select name,samaccountname
