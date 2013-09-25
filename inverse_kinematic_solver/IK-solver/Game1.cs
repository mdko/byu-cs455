using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.GamerServices;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;

namespace IK_solver
{
    struct PointF
    {
        private float xval;
        private float yval;
        private float zval;
        public float X
        {
            get
            {
                return xval;
            }
            set
            {
                xval = value;
            }
        }
        public float Y
        {
            get
            {
                return yval;
            }
            set
            {
                yval = value;
            }
        }
        public float Z
        {
            get
            {
                return zval;
            }
            set
            {
                zval = value;
            }
        }
        public PointF(float _xval, float _yval, float _zval)
        {
            xval = _xval;
            yval = _yval;
            zval = _zval;
        }
    }
    /// <summary>
    /// This is the main type for your game
    /// </summary>
    public class Game1 : Microsoft.Xna.Framework.Game
    {
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        // simple game to load a model and move it around a little. 
        // see http://msdn.microsoft.com/en-us/library/bb197293.aspx
        // for details. 
        Model myModel;
        Model truss;
        // In-hinge position is modelPosition (0,0,0)
        Vector3 modelPosition = Vector3.Zero;
        Vector3 cameraPosition = new Vector3(0.0f, 0.0f, 6000.0f/*150.0f*/ /*5000.0f*/);
        Vector3 targetPoint = new Vector3(-100.0f, 100.0f, 0.0f); // TODO allow user to choose point, this vector will change
        float aspectRatio;
        Matrix viewMatrix;
        Matrix projectionMatrix;
        Model[] segments;
        float deltaX;
        const int segmentCount = 8;
        const int segmentLength = 20;
        const float initialModelRotation = -270.0f;//270.0f; //TODO this was big problem, inverting the locations of everything...
        float[] segmentRelRotations;        // Relative to the parent
        PointF[] segmentAbsEndPositions;    // Absolute positions in world
        int[] segmentLengths;
        DotNetMatrix.GeneralMatrix jacobian;
        float[] jointPositionVelocties;
        Vector2 desiredChangeVector;
        Vector3 endEffector;
        float angleScalingFactor = 0.001f;
        float trussScalingFactor = 30.0f;
        int screenWidth;
        int screenHeight;
        float fieldOfView = 45.0f;

        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
        }

        /// <summary>
        /// Allows the game to perform any initialization it needs to before starting to run.
        /// This is where it can query for any required services and load any non-graphic
        /// related content.  Calling base.Initialize will enumerate through any components
        /// and initialize them as well.
        /// </summary>
        protected override void Initialize()
        {
            // TODO: Add your initialization logic here
            base.Initialize();
            segmentRelRotations = new float[segmentCount];
            segmentAbsEndPositions = new PointF[segmentCount];
            segmentLengths = new int[segmentCount];
            jointPositionVelocties = new float[segmentCount];

            for (int segmentN = 0; segmentN < segmentCount; segmentN++) 
            {
                segmentRelRotations[segmentN] = (segmentN == 0) ? initialModelRotation : 0.0f; // +(segmentN * 20);
                segmentAbsEndPositions[segmentN] = new PointF(0.0f, (segmentN + 1) * -segmentLength, 0.0f);
                segmentLengths[segmentN] = segmentLength;
                jointPositionVelocties[segmentN] = 0.0f;
            }

            jacobian = new DotNetMatrix.GeneralMatrix(2, segmentCount);
            desiredChangeVector = new Vector2(0.0f);
            endEffector = new Vector3(0.0f);

            this.IsMouseVisible = true;
            screenWidth = graphics.GraphicsDevice.Viewport.Width;
            screenHeight = graphics.GraphicsDevice.Viewport.Height;
        }

        /// <summary>
        /// LoadContent will be called once per game and is the place to load
        /// all of your content.
        /// </summary>
        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);

            // TODO: use this.Content to load your game content here
            // mdj this is where we load the spaceship.
            // LEAVE OFF the filename extension.  I miss that everytime. 
            myModel = Content.Load<Model>("Models\\p1_wedge");
            segments = new Model[segmentCount];
            for (int i = 0; i < segmentCount; i++)
                segments[i] = Content.Load<Model>("Models\\Steel-truss");
            deltaX = 10.0f;

            aspectRatio = graphics.GraphicsDevice.Viewport.AspectRatio;
            viewMatrix = Matrix.CreateLookAt(cameraPosition, Vector3.Zero, Vector3.Up);
            projectionMatrix = Matrix.CreatePerspectiveFieldOfView(MathHelper.ToRadians(fieldOfView), aspectRatio, 1.0f, 10000.0f);
        }

        /// <summary>
        /// UnloadContent will be called once per game and is the place to unload
        /// all content.
        /// </summary>
        protected override void UnloadContent()
        {
            // TODO: Unload any non ContentManager content here
        }

        /// <summary>
        /// Allows the game to run logic such as updating the world,
        /// checking for collisions, gathering input, and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            // Allows the game to exit
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed)
                this.Exit();

            MouseState ms = Mouse.GetState();
            if (ms.LeftButton == ButtonState.Pressed)
            {
                targetPoint.X = ms.X - (screenWidth / 2);
                targetPoint.Y = -(ms.Y - (screenHeight / 2));

                //System.Console.WriteLine("Screen size: Width = " + screenWidth + " Height = " + screenHeight);
                //System.Console.WriteLine("Button pressed, regular coordinates are " + ms.X + ", " + ms.Y);
                System.Console.WriteLine("Button pressed, converted coordinates are " + targetPoint.X + ", " + targetPoint.Y);
            }

            // TODO: Add your update logic here
            //Compute the translations and rotations
            //--------------------------------------
            //At the beginning of each round, I know:
            // -angles between joints
            // -position of in-hinge
            //So need to store before all of this:
            // -an array of rotations of each segment (angles relative to parent)
            // -an array of absolute end positions of each segment
            // -an array of lengths of each segment (not super necessary when all models are same, like in this example)
            float worldCumulativeAngle = 0.0f;
            for (int joint_n = 0; joint_n < segmentCount; joint_n++)
            {
                //1.For each joint
                //    1.Find the absolute angle
                //    2.To find the absolute position of the end of the segment (traverse arm computing absolute positions as I go)
                float angleRelToParent = segmentRelRotations[joint_n];
                float currAbsAngle = angleRelToParent + worldCumulativeAngle;
                worldCumulativeAngle += angleRelToParent;

                float prevX = (joint_n == 0) ? modelPosition.X : segmentAbsEndPositions[joint_n - 1].X;
                float prevY = (joint_n == 0) ? modelPosition.Y : segmentAbsEndPositions[joint_n - 1].Y;
                float relEndXPos = segmentLengths[joint_n] * (float)Math.Cos(MathHelper.ToRadians(currAbsAngle));
                float relEndYPos = segmentLengths[joint_n] * (float)Math.Sin(MathHelper.ToRadians(currAbsAngle));

                segmentAbsEndPositions[joint_n].X = relEndXPos + prevX;
                segmentAbsEndPositions[joint_n].Y = relEndYPos + prevY;

                //If at last strut/segment, record end effector position
                //Figure out desired change vector also
                if (joint_n == (segmentCount - 1))
                {
                    endEffector.X = segmentAbsEndPositions[joint_n].X;
                    endEffector.Y = segmentAbsEndPositions[joint_n].Y;
                    desiredChangeVector.X = (targetPoint.X - endEffector.X);
                    desiredChangeVector.Y = (targetPoint.Y - endEffector.Y);
                }
            }

            for (int joint_n = 0; joint_n < segmentCount; joint_n++)
            {
                //2.For each joint
                //    1.Find the vector the connects the end of the segment with the end effector position
                //    2.Compute the cross product of the axis of rotation (0,0,1) with that vector.
                //    3.This goes in the Jacobian
                //TODO check this
                float segmentStartX = (joint_n == 0) ? modelPosition.X : segmentAbsEndPositions[joint_n - 1].X;
                float segmentStartY = (joint_n == 0) ? modelPosition.Y : segmentAbsEndPositions[joint_n - 1].Y;
                float segmentStartZ = (joint_n == 0) ? modelPosition.Z : segmentAbsEndPositions[joint_n - 1].Z;
                Vector3 jointToEndEffectorVector = new Vector3(endEffector.X - segmentStartX,
                                                               endEffector.Y - segmentStartY,
                    /*TODO add for allowing rotation around any axis. The following line should just be 0 right now, unimplemented...*/
                                                               endEffector.Z - segmentStartZ);

                Vector3 vectorCrossWith = new Vector3(0, 0, 1);
                Vector3 crossedVector = Vector3.Cross(vectorCrossWith, jointToEndEffectorVector);
                float jacobianSx = crossedVector.X;
                float jacobianSy = crossedVector.Y;
                jacobian.SetElement(0, joint_n, jacobianSx);
                jacobian.SetElement(1, joint_n, jacobianSy);
            }

            //3.Multiply the transpose of the Jacobian with the vector which connects the end effector to the target (desired motion vector).
            DotNetMatrix.GeneralMatrix jacobianTranspose = jacobian.Transpose();
            for (int rowN = 0; rowN < jacobianTranspose.RowDimension; rowN++)
            {
                Vector2 transposeRow = new Vector2();
                transposeRow.X = (float)jacobianTranspose.GetElement(rowN, 0);
                transposeRow.Y = (float)jacobianTranspose.GetElement(rowN, 1);

                float changeJointAngles = (transposeRow.X * desiredChangeVector.X) + (transposeRow.Y * desiredChangeVector.Y);
                //4.Get back a rotation amount for each joint. Scale that rotation amount by a small value.
                jointPositionVelocties[rowN] = angleScalingFactor * changeJointAngles;
                //5.Add that rotation amount to each joint angle
                segmentRelRotations[rowN] += jointPositionVelocties[rowN];
            }
            base.Update(gameTime);
        }

        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            // Copy any parent transforms.
            Matrix[] transforms = new Matrix[myModel.Bones.Count];
            myModel.CopyAbsoluteBoneTransformsTo(transforms);
            float cumulAngle = initialModelRotation;

            // Draw each truss. Each truss (model) can have multiple meshes, so loop within the drawing of each truss.
            for (int i = 0; i < segmentCount; i++) // For each joint
            {
                Matrix[] otherTransforms = new Matrix[segments[i].Bones.Count];
                float xPos = (i == 0) ? modelPosition.X : segmentAbsEndPositions[i - 1].X;
                float yPos = (i == 0) ? modelPosition.Y : segmentAbsEndPositions[i - 1].Y;
                float zPos = 0.0f;
                //System.Console.WriteLine("Starting position of truss " + i + ":x=" + trussScalingFactor * xPos
                //                                                           + " y=" + trussScalingFactor * yPos
                //                                                           + " z=" + trussScalingFactor * zPos);
                
                Vector3 perSegmentModelPosition = new Vector3(trussScalingFactor * xPos, 
                                                              trussScalingFactor * yPos, 
                                                              trussScalingFactor * zPos);
                segments[i].CopyAbsoluteBoneTransformsTo(otherTransforms);
                cumulAngle += segmentRelRotations[i];
                //System.Console.WriteLine("Angle: " + cumulAngle);
                foreach (ModelMesh mesh in segments[i].Meshes)
                {
                    foreach (BasicEffect effect in mesh.Effects)
                    {
                        effect.FogEnabled = true;
                        //effect.EnableDefaultLighting();
                        effect.World = otherTransforms[mesh.ParentBone.Index] *
                            Matrix.CreateScale(trussScalingFactor) *
                            Matrix.CreateRotationZ(MathHelper.ToRadians(cumulAngle)) *
                            //Matrix.CreateRotationY(MathHelper.ToRadians(modelRotation)) * 
                            //Matrix.CreateRotationX(modelRotation * i) *
                            Matrix.CreateTranslation(perSegmentModelPosition)
                            ;
                        effect.View = viewMatrix;
                        effect.Projection = projectionMatrix;
                    }
                    mesh.Draw();
                }
            }


            // Draw the model. A model can have multiple meshes, so loop.
            //foreach (ModelMesh mesh in myModel.Meshes)
            //{
            //    // This is where the mesh orientation is set, as well as our camera and projection.
            //    foreach (BasicEffect effect in mesh.Effects)
            //    {
            //        effect.EnableDefaultLighting();
            //        effect.World = transforms[mesh.ParentBone.Index] * Matrix.CreateRotationY(modelRotation) * Matrix.CreateTranslation(modelPosition);
            //        effect.View = viewMatrix;
            //        effect.Projection = projectionMatrix;
            //    }

            //    // Draw the mesh, using the effects set above.
            //    //mesh.Draw();
            //}
            base.Draw(gameTime);
        }
    }
}