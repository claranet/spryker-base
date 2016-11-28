<?php

echo "<h1>Yves</h1><p>Spryker container framework on <pre>".system("hostname -f")."</pre> with ip address <pre>".system("getent hosts `hostname` | awk '{print $1}'")."</pre></p><hr/>";

phpinfo();
