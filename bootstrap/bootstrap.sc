import $ivy.`org.jupyter-scala::spark:0.4.0-RC4`

org.apache.log4j.Logger.getRootLogger.setLevel(org.apache.log4j.Level.toLevel("ERROR"))

interp.load.cp(ammonite.ops.Path.root/'etc/'hadoop/'conf)
interp.load.cp(ammonite.ops.Path.root/'etc/'hive/'conf)

@transient val sparkConf = new org.apache.spark.SparkConf

@transient val sparkClassServer = new jupyter.spark.internals.ClassServer(kernel.sess.frames)
sparkConf.set("spark.repl.class.uri", sparkClassServer.uri.toString)

@transient lazy val spark =
  org.apache.spark.sql.SparkSession.builder.config(sparkConf).enableHiveSupport.getOrCreate
@transient lazy val sc = spark.sparkContext
@transient lazy val sql = spark.sql _

// Classpath hooks stolen from jupyter-scala project
interp.load.onJarAdded { jars =>
  if (!sc.isStopped)
    for (jar <- jars)
      sc.addJar(jar.toURI.toString)
}

kernel.onExit { _ =>
  if (!sc.isStopped)
    sc.stop()
}
