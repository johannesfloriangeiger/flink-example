package org.example;

import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;
import org.apache.flink.api.common.serialization.Encoder;
import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.api.java.io.TextInputFormat;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink;
import org.apache.flink.streaming.api.functions.source.FileProcessingMode;

import java.nio.charset.StandardCharsets;
import java.text.MessageFormat;

public class Main {

    public static void main(final String[] args) throws Exception {
        final StreamExecutionEnvironment streamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment();

        final String bucket = KinesisAnalyticsRuntime.getApplicationProperties()
                .get("FlinkApplicationProperties")
                .getProperty("bucket");

        final String inputPath = MessageFormat.format("s3://{0}/input.txt", bucket);
        final TextInputFormat textInputFormat = new TextInputFormat(new Path(inputPath));

        final String outputPath = MessageFormat.format("s3://{0}/output", bucket);
        final Path basePath = new Path(outputPath);
        final Encoder<String> simpleStringEncoder = new SimpleStringEncoder<>(StandardCharsets.UTF_8.name());
        final StreamingFileSink<String> streamingFileSink = StreamingFileSink.forRowFormat(basePath, simpleStringEncoder)
                .build();

        streamExecutionEnvironment.readFile(textInputFormat, inputPath, FileProcessingMode.PROCESS_CONTINUOUSLY, 100)
                .map(String::toUpperCase)
                .addSink(streamingFileSink);

        streamExecutionEnvironment.execute();
    }
}