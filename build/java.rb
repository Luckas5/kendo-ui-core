JAVA_WRAPPERS_ROOT = 'wrappers/java/'
POM = JAVA_WRAPPERS_ROOT + 'pom.xml'

JSP_TAGLIB_ROOT = JAVA_WRAPPERS_ROOT + 'kendo-taglib/'
JAR_NAME = "kendo-taglib-#{VERSION}.jar"

JSP_TAGLIB_JAR = "#{JSP_TAGLIB_ROOT}target/#{JAR_NAME}"
JSP_TAGLIB_POM = "#{JSP_TAGLIB_ROOT}pom.xml"
JSP_TAGLIB_SRC_ROOT = JSP_TAGLIB_ROOT + 'src/'
JSP_TAGLIB_SRC = FileList[JSP_TAGLIB_SRC_ROOT + '**/*'].exclude('**/target/*')

SPRING_DEMOS_ROOT = JAVA_WRAPPERS_ROOT + 'spring-demos/'
SPRING_DEMOS_WAR = "#{SPRING_DEMOS_ROOT}target/sprind-demos-#{VERSION}.war"
SPRING_DEMOS_SRC_ROOT = SPRING_DEMOS_ROOT + 'src/'
SPRING_DEMOS_SRC = FileList[SPRING_DEMOS_SRC_ROOT + '**/*'].exclude('**/target/*')

# Update a pom.xml file when the VERSION changes
class PomTask < Rake::FileTask
    include Rake::DSL

    def execute(args=nil)
        mvn(name, "versions:set -DnewVersion=#{VERSION} -DgenerateBackupPoms=false")
    end

    def needed?
        super || !File.read(name).include?(VERSION)
    end
end

def pom_file(*args, &block)
    PomTask.define_task(*args, &block)
end

# Update the root pom.xml when the VERION changes. Will update the child pom.xml files.
pom_file POM

# Build the kendo-taglib-*.jar by running maven
file JSP_TAGLIB_JAR => [POM, JSP_TAGLIB_SRC].flatten do

    mvn(JSP_TAGLIB_POM, 'package')

end

# Build the spring-demos-*.war by running maven
file SPRING_DEMOS_WAR => [POM, JSP_TAGLIB_JAR, SPRING_DEMOS_SRC].flatten do

    mvn(POM, 'package')

end

file_copy :to => 'dist/bundles/trial/wrappers/jsp/spring-demos/pom.xml',
          :from => SPRING_DEMOS_ROOT + 'pom.xml'

file_copy :to => "dist/bundles/trial/wrappers/jsp/spring-demos/src/main/webapp/WEB-INF/lib/#{JAR_NAME}",
          :from => JSP_TAGLIB_JAR

# Patch POM - remove parent etc.
file 'dist/bundles/trial/wrappers/jsp/spring-demos/pom.xml' do |t|
    pom = File.read(t.name)

    PROJECT = <<-eos
    <groupId>com.kendoui</groupId>
    <version>#{VERSION}</version>
    eos

    pom.sub!(/<parent>(.|\n)*<\/parent>/, PROJECT)
    pom.sub!(/<dependency>\n\s*<groupId>com\.kendoui(.|\n)*<\/dependency>/, '')

    BUILD = <<-eos
    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <configuration>
                        <source>1.7</source>
                        <target>1.7</target>
                    </configuration>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>
    eos

    pom.sub!(/<build>(.|\n)*<\/build>/, BUILD)

    File.open(t.name, 'w') do |file|
        file.write(pom)
    end
end

namespace :java do
    desc('Build the Kendo Tag Library')
    task :taglib => JSP_TAGLIB_JAR

    desc('Build the Kendo Spring Demos')
    task :spring => SPRING_DEMOS_WAR
end
