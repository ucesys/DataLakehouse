SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
LIB_DIR="$SCRIPT_DIR/../lib"

mkdir -p "$LIB_DIR"

wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.2/hadoop-common-3.3.2.jar -O "$LIB_DIR/hadoop-common-3.3.2.jar"
wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.2/hadoop-aws-3.3.2.jar -O "$LIB_DIR/hadoop-aws-3.3.2.jar"
wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-auth/3.3.2/hadoop-auth-3.3.2.jar -O "$LIB_DIR/hadoop-auth-3.3.2.jar"
wget https://repo1.maven.org/maven2/org/apache/hadoop/thirdparty/hadoop-shaded-guava/1.1.1/hadoop-shaded-guava-1.1.1.jar -O "$LIB_DIR/hadoop-shaded-guava-1.1.1.jar"
wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.1026/aws-java-sdk-bundle-1.11.1026.jar -O "$LIB_DIR/aws-java-sdk-bundle-1.11.1026.jar"