#LDAP configuration
import ldap
from django_auth_ldap.config import LDAPSearch
AUTHENTICATION_BACKENDS = (
    'django_auth_ldap.backend.LDAPBackend',
    'django.contrib.auth.backends.ModelBackend',
)

AUTH_LDAP_SERVER_URI = 'ldap://192.168.2.2'
AUTH_LDAP_BIND_DN = 'CN=admin,OU=IT,DC=coral,DC=coral,DC=org'
#AUTH_LDAP_BIND_PASSWORD = "coral"
AUTH_LDAP_USER_SEARCH = LDAPSearch("OU=IT,DC=coral,DC=coral,DC=org", ldap.SCOPE_SUBTREE, "(&(objectClass=person)(sAMAccountName=%(user)s))")

AUTH_LDAP_USER_ATTR_MAP = {
     "first_name": "givenName",
     "last_name": "sn",
     "email": "mail"
}
print AUTH_LDAP_USER_ATTR_MAP
