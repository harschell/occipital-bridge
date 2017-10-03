/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Some utilities for helping annotate the class properties in the Unity editor inspector panel.
 */
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;

public class CommentAttribute : PropertyAttribute {
     public readonly string comment;
     public readonly int height;
     
     public CommentAttribute(string comment, int height = 20) {
         this.comment = comment;
         this.height = height;
     }
 }

[CustomPropertyDrawer(typeof(CommentAttribute))]
 public class CommentDrawer : DecoratorDrawer {
     CommentAttribute commentAttribute { get { return (CommentAttribute)attribute; } }
     
     public override float GetHeight() {
         return commentAttribute.height;
     }
     
     public override void OnGUI(Rect position) {
         EditorGUI.LabelField(position,new GUIContent(commentAttribute.comment));
     }
 }

 
#else // UNITY_EDITOR

public class CommentAttribute : PropertyAttribute {
     public CommentAttribute(string comment, int height = 20) {}
}
 
#endif
